;; mirror env.sh PATH setting for compilation
((nil .
      ((eval . (let* ((prxpty-path (file-name-directory
                                    (locate-dominating-file default-directory ".dir-locals.el")))
                      (node-modules-bin-path (concat prxpty-path ".bin"))
                      (bin-path (concat prxpty-path "bin"))
                      (path (concat bin-path ":" node-modules-bin-path ":" (getenv "PATH")))
                      (set-path (concat "PATH=" path))
                      (new-env (cons set-path compilation-environment)))
                 (setq-local compilation-environment
                             (remove-duplicates new-env :test 'string=)))))))
