#!/bin/bash
set -e

# \TEST00 single to many output filters (passthru)
function do_test {
  local TEMP=$(mktemp)
  $* bash -c "$CMD" > $TEMP
  echo -en "${GOLD}\r\n" | cmp $TEMP -
}

CMD='echo hey' GOLD='hey' do_test prxpty
CMD='echo hey' GOLD='hey' do_test prxpty -o cat
CMD='echo hey' GOLD='hey' do_test prxpty -i cat
CMD='echo hey' GOLD='hey' do_test prxpty -i cat -o cat
CMD='echo hey' GOLD='hey' do_test prxpty -i cat -i cat -o cat
CMD='echo hey' GOLD='hey' do_test prxpty -o cat -o cat
CMD='echo hey' GOLD='hey' do_test prxpty -i cat -i cat -i cat -i cat -o cat -o cat


# \TEST01 trivial output filter(s)
prxpty -i cat -o "tr h H" echo hello | cmp <(echo -ne 'Hello\r\n') -
prxpty -i cat -o "tr h H" -o "tr o O" echo hello | cmp <(echo -ne 'HellO\r\n') -


# \TEST02 can automatically push non-tty input through prxpty
TEMP=$(mktemp)
echo boo | prxpty bash -c "read A && echo \$A" > $TEMP
cmp $TEMP <(echo -en 'boo\r\nboo\r\n')


# \TEST03 input filter(s)
TEMP=$(mktemp)
echo boo | prxpty -i cat bash -c "read A && echo \$A" > $TEMP
cmp $TEMP <(echo -en 'boo\r\nboo\r\n')

TEMP=$(mktemp)
echo boo | prxpty -i cat -i cat bash -c "read A && echo \$A" > $TEMP
cmp $TEMP <(echo -en 'boo\r\nboo\r\n')

TEMP=$(mktemp)
echo boo | prxpty -i "sed -u s/b/B/" -i "sed -u s/B/C/" bash -c "read A && echo \$A" > $TEMP
cmp $TEMP <(echo -en 'Coo\r\nCoo\r\n')


# \TEST04 filter0: passthru input stream (check interactively)
TEMP=$(mktemp)
echo boo | prxpty -i "coffee src/filter0.coffee" -i "sed -u s/b/B/" bash -c "read A && echo \$A" > $TEMP
cmp $TEMP <(echo -en 'Boo\r\nBoo\r\n')
