# prxpty

Attach and develop stream filter pipelines to pseudoterminals' `stdin` and
`stdout`. Terminal apps to have custom compression, new interactive features
(menus, autocomplete, etc), and more without modification.

    # start an interactive bash session w/ filtered stdin, stdout
    prxpty -o filterStdout -i filterStdin bash

    # start an ssh session with custom compression over-the-line
    prxpty -o decode ssh -t host prxpty -o encode cmd

Record interactive sessions,

    # record interactive shell
    prxpty -i 'log CI.log' -o 'log CO.log' bash

    # record interactive ssh (replies from server)
    prxpty -o 'log COS.log' ssh -t localhost prxpty -o 'log SO.log'

, and use results to verify individual or paired filters (e.g. encode /
decode):

    # validate `decode` `encode` pair w/o message bounds
    cmp file <(cat file | encode | decode)

    # validate `decode` produces pre-encoded stream (w/ message bounds)
    cmp COS.log <(play SO.log | DBG=all decode)




## Usage

`prxpty` filters the input and output of a given command while run within a
pseudoterminal. Filters are specified as shell commands that manipulate
traffic from `stdin` to `stdout` (`-i`, `-o` options):

    prxpty -i tac -o cat bash

               (i)ncoming    caller  ---> tac ->          ---> bash

                                                 Internal
                                                 Terminal
                                                 Emulator

               (o)utgoing    caller  <--- cat <-          <--- bash


Repeated options specify additional filters onto their respective pipes:

    prxpty -i tac -i cat -o cat -o tac bash

        (i)ncoming    caller  ---> tac -> cat ->          ---> bash

                                                 Internal
                                                 Terminal
                                                 Emulator

        (o)utgoing    caller  <--- cat <- tac <-          <--- bash

These options suffixed with 'r' or 's' indicate more specific piping siphins
with respect to the "Internal Terminal Emulator".

    prxsh -ir .. -is .. -or .. -os ..

        (i)ncoming      caller  ---> -ir ->            -> -is ---> bash

                                             Internal
                                             Terminal
                                             Emulator

        (o)utgoing      caller  <--- -os <-            <- -or <--- bash

Thus, `-ir` is synonymous with `-i` as is `-os` with `-o`.

The explicit pipes facilitate fine-grained debugging.


### Application

`prxpty` enables full interactive sessions in the presence of filtering:

    # interactive bash through filtering
    prxpty -i encode -o decode bash

    # ssh through filtering
    prxpty -o lf2crlf -o atob -o decode -o crlf2lf \
      ssh -t <host> prxpty -o encode -o btoa <cmd>

> Practical Note: `ssh` adds a carriage return (char 13) before each line feed
> (char 10) from server to client. `crlf2lf` reverses this to avoid message
> corruption and `lf2crlf` is applied after decode to mimic ssh behavior.



## Filter Development

### log, play

Record, encode, and reenact stream messages.

* `log [filename]` - record `stdin` messages as JSON records.
    * When given, emit logs to `filename` and pipe `stdin` to `stdout`.
        * Logs of format `base64(time) + base64(message)`
    * Otherwise, emit log to `stdout`.

* `play <log> <cmds>` - pipe messages from `log` to `cmd` with respect to
  message bounds implied by separate records of the incoming `log` (see
  `SOCK_SEQPACKET`).
    * Invokes each of `cmds` with environment `DBG=stdin`.
    * `cmds` pipe JSON messages from left to right.
    * Pipes one line per record of JSON `log` to first of `cmds`.
    * Outputs `stdout` of final `cmds` (JSON messages)
    * `DBG` interpreted by CACHENET stream API:
        * Each record parsed into message.
        * Messages individually passed to incoming stream in entirety.

Replay traffic across a pipeline while incorporating message disjunctions:

    # record interactive session
    prxpty -o 'log RECV' bash prxpty -o 'log SENT' bash

    # replay on pipeline; is client output reproduced?
    diff RECV <(play SENT | DBG=all encode | DBG=all decode)

    # can compensate for missing ssh carriage return before linefeed on client?
    prxpty -o 'log RECV' ssh -t localhost prxpty -o 'log SENT'
    diff RECV <(play SENT | DBG=all lf2crlf)


### Stream API (simulation)

Only filters that utilize the _CACHENET Stream API_ will interpret streams
from `play` and generate for log comparison. In doing so, those filters will
receive messages discretized per each record of `play`'s incoming log.

Logs are formatted:
* One message per line
* Each line formatted as an ASCII string `base64(time) + base64(message)`

The API is a transparent wrapper around `process.stdin` and `process.stdout`
dictated by the `DBG` environment variable:

* upon `DBG=stdout` or `DBG=all`
    * `stdout.write` emits exactly one message in log form
* upon `DBG=stdin` or `DBG=all`
    * `stdin.on('data')` calls back upon each incoming log message



## Organization and Conventions

`prxpty`'s purpose is to provide an environment to build out stream filters of
any complexity. `prxpty` assumes the importance of chronology of streams
attached to running applications.

As a labority, then, the source and its conventions seek to maximize
compartmentalization and big-data as a part of test-runs.


### Directory Structure

    README.md
    package.json
    package-lock.json
    node_modules/
    env.sh
    test.sh              # assumes env.sh setup PATH, etc
    src/
        node_modules/    # local require()
        prxpty.js
        filters/
          filter0/       # directory per filter
          filter1/
        test/            # described below
    bin/                 # symlinks to executables in src/
    out/                 # ignored, temporary dir for test.sh results

* `npm start`: `env.sh` to setup PATH, etc
* `npm test`: `env.sh && test.sh`


### Test Conventions

The directory tree layout seeks to simply indicate files' purposes and
maintain a small footprint,

    test/
        00_prxpty.sh
        encode-decode/
            README.md           # optional
            00_inverse.sh
            01_disjoint.sh
            02_ssh.sh
        01_pair0/
            00_env.sh
            01_encode-decode -> ../encode-decode
        02_pair2/
            00_env.sh
            01_encode0.coffee
            02_decode0.coffee
            03_encode-decode -> ../encode-decode

On `npm test`, evaluate each directory and `+x` script in `test/` that match
`[0-9]+_.*`. Recursively evaluate directories similarly.

Submodules test prior to their aggregate modules through their scripts'
numeric prefix ordering.

Directories provide the opportunity to document a module with a README.

Unnumbered items provide re-usable generalized tests and routines that are not
evaluated by `npm test`. Execute these by providing a numerically prefixed
symlink from a calling module to the item. Pass parameters by setting
environment variables in a preceding script, e.g. `00_env.sh`.

The `encode-decode` directory tests an encoder / decoder pair given their
filenames on the command line: `main.sh encoder0 decoder0`.

#### Test Invocation

`test.sh` invokes testing,

    # run all tests
    ./test.sh

    # ./test <path relative to test/> runs a dir or particular test
    ./test.sh 02_pair2

Results are aggregated by stream to `out/<test path>.out` and `out/<test
path>.err`.


### Validating Individual Filters

Each filter resides in an individual directory `src/filters/<name>` and
developed as distinct projects. Each will have a `README.md`, perhaps
`node_modules`, and dedicated tests for development. The tests move into
`test/` as they solidify.


### Validating Encoder / Decoder (Paired Filters)

Encoder and decoder are abstracted as stream filters. The pair will function
at large upon successful execution of two tests:

1. The pair are an inverse:

    `cmp <(cat src | encode | decode) src`

2. The pair handle scaled, disjoint data:

    `diff COS <(play SOS encode decode)`

3. The pair handle replay of an interactive `ssh` session:

    * Recording of `ssh` session:  `prxpty -os 'log COS' ssh -t <host> prxpty
        -o 'log SO'`

    * Test filters while compensating for `ssh` carriage return insertion:
        `diff COS <(play SO encode crlf2lf decode lf2crlf)`

4. *(Optional)* Interactively, the following runs,

    `prxpty -o lf2crlf -o decode -o crlf2lf ssh -t <host> prxpty -o encode`

Encoder and decoder may be developed independently as stream filters. The pair
is valid upon executing the above successfully when plugged into the `encode`
and `decode` placeholders.


## Benchmarking

Benchmarks are handled as unordered tests explicitly invoked with
`test.sh`. Metrics are collected via typical OS tools to monitor stream
characteristics and process behavior.

Standard metrics define dimensions of comparison between the filters with
fixed names:

* memory
* runtime
* transfer

Bench scripts output JSON to `out/<test path>.out`.



<!-- expects `npm i -g markdown-styles` -->
<!--
  -- Local Variables:
  -- eval: (olivetti-mode);
  -- eval: (local-set-key (kbd "C-c C-c") 'compile);
  -- compile-command: "generate-md --layout github --input ./README.md --output out/html && cd out/html && inliner README.html > README.min.html 2>/dev/null && scp README.min.html nickelspike:static/9f48154b-9f46-4a58-856d-6e96fddf83da";
  -- End:
-->
