;; mirror env.sh PATH setting for compilation
((nil .
      ((eval . (let* ((prxpty-path (file-name-directory
                                    (locate-dominating-file default-directory ".dir-locals.el")))
                      (node-modules-bin-path (concat prxpty-path ".bin"))
                      (bin-path (concat prxpty-path "bin"))
                      (path (concat bin-path ":" node-modules-bin-path ":" (getenv "PATH")))
                      (path-def (concat "PATH=" path))
                      (prxpty-def (concat "PRXPTY=" prxpty-path))
                      (new-env (cons prxpty-def (cons path-def compilation-environment))))
                 (setq-local compilation-environment
                             (remove-duplicates new-env :test 'string=))
                 (if buffer-file-name
                     (setq-local compile-command
                                 (concat "cd " prxpty-path " && ./chk -s " buffer-file-name))))))))
