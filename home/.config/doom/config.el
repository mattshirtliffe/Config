;;; private/my/config.el -*- lexical-binding: t; -*-

(load! "+bindings")
(load! "+org")
(load! "+ui")

(setq doom-scratch-buffer-major-mode 'emacs-lisp-mode)

(use-package atomic-chrome
  :ensure t
  :defer 5                              ; since the entry of this
                                        ; package is from Chrome
  :config
  (setq atomic-chrome-url-major-mode-alist
        '(("github\\.com"        . gfm-mode)
          ("emacs-china\\.org"   . gfm-mode)
          ("stackexchange\\.com" . gfm-mode)
          ("stackoverflow\\.com" . gfm-mode)))

  (defun +my/atomic-chrome-mode-setup ()
    (setq header-line-format
          (substitute-command-keys
           "Edit Chrome text area.  Finish \
`\\[atomic-chrome-close-current-buffer]'.")))

  (add-hook 'atomic-chrome-edit-mode-hook #'+my/atomic-chrome-mode-setup)

  (atomic-chrome-start-server))

(def-package! avy
  :commands (avy-goto-char-timer)
  :init
  (setq avy-timeout-seconds 0.2)
  (setq avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?q ?w ?e ?r ?u ?i ?o ?p))
  )

(after! company
  (setq company-minimum-prefix-length 2
        company-quickhelp-delay nil
        company-show-numbers t
        company-global-modes '(not comint-mode erc-mode message-mode help-mode gud-mode)
        ))

(def-package! company-lsp
  :load-path "~/Dev/Emacs/company-lsp"
  :after company
  :init
  (setq company-transformers nil company-lsp-cache-candidates nil)
  )

(set-lookup-handlers! 'emacs-lisp-mode :documentation #'helpful-at-point)

(def-package! eglot)

(after! eshell
  (defun eshell/l (&rest args) (eshell/ls "-l" args))
  (defun eshell/e (file) (find-file file))
  (defun eshell/md (dir) (eshell/mkdir dir) (eshell/cd dir))
  (defun eshell/ft (&optional arg) (treemacs arg))

  (defun eshell/up (&optional pattern)
    (let ((p (locate-dominating-file
              (f-parent default-directory)
              (lambda (p)
                (if pattern
                    (string-match-p pattern (f-base p))
                  t)))
             ))
      (eshell/pushd p)))
  )

(def-package! eshell-autojump)

(def-package! evil-nerd-commenter
  :commands (evilnc-comment-or-uncomment-lines)
  )

(after! evil-snipe
  (setq evil-snipe-scope 'buffer)
  )

(after! flycheck
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (setq-default flycheck-disabled-checkers '(c/c++-clang c/c++-cppcheck c/c++-gcc))
  )

(after! git-link
  (defun git-link-llvm (hostname dirname filename branch commit start end)
      (format "https://github.com/llvm-mirror/%s/tree/%s/%s"
              (file-name-base dirname)
              (or branch commit)
              (concat filename
                      (when start
                        (concat "#"
                                (if end
                                    (format "L%s-%s" start end)
                                  (format "L%s" start)))))))
  (defun git-link-musl (hostname dirname filename branch commit start end)
      (format "http://git.musl-libc.org/cgit/%s/tree/%s%s%s"
              (file-name-base dirname)
              filename
              (if branch "" (format "?id=%s" commit))
              (if start (concat "#" (format "n%s" start)) "")))
  (defun git-link-sourceware (hostname dirname filename branch commit start end)
    (format "https://sourceware.org/git/?p=%s.git;a=blob;hb=%s;f=%s"
            (file-name-base dirname)
            commit
            (concat filename
                    (when start
                      (concat "#" (format "l%s" start))))))
  (add-to-list 'git-link-remote-alist '("git.llvm.org" git-link-llvm))
  (add-to-list 'git-link-remote-alist '("git.musl-libc.org" git-link-musl))
  (add-to-list 'git-link-remote-alist '("sourceware.org" git-link-sourceware))
  )

(def-package! link-hint
  :commands link-hint-open-link link-hint-open-all-links)

(after! lispy
  (setq lispy-outline "^;; \\(?:;[^#]\\|\\*+\\)"
        lispy-outline-header ";; "
        lispy-ignore-whitespace t)
  (map! :map lispy-mode-map
        :i "C-c (" #'lispy-wrap-round
        :i "_" #'special-lispy-different
        "d" nil
        :i [remap delete-backward-char] #'lispy-delete-backward))

;(remove-hook 'emacs-lisp-mode-hook #'lispy-mode)

;; Also use lispyville in prog-mode for [ ] < >
(after! lispyville
  ;; (lispyville-set-key-theme
  ;;  '(operators
  ;;    c-w
  ;;    (escape insert)
  ;;    (slurp/barf-lispy)
  ;;    additional-movement))
  (map! :map lispyville-mode-map
       :i "C-w" #'backward-delete-char
       :n "M-j" nil
       :n "H" #'sp-backward-sexp
       :n "L" #'sp-forward-sexp
       )
  (map! :map emacs-lisp-mode-map
        :n "gh" #'helpful-at-point
        :n "gl" (λ! (let (lispy-ignore-whitespace) (call-interactively #'lispyville-right)))
        :n "C-<left>" #'lispy-forward-barf-sexp
        :n "C-<right>" #'lispy-forward-slurp-sexp
        :n "C-M-<left>" #'lispy-backward-slurp-sexp
        :n "C-M-<right>" #'lispy-backward-barf-sexp
        :i "C-w" #'delete-backward-char
        :n "<tab>" #'lispyville-prettify
        :localleader
        :n "e" (λ! (save-excursion (forward-sexp) (eval-last-sexp nil)))
        )
  )

(def-package! lsp-mode
  :load-path "~/Dev/Emacs/lsp-mode"
  :commands lsp
  :init
  (setq lsp-auto-guess-root t)
  )

(after! lsp-clients
  (remhash 'clangd lsp-clients)
  )

(def-package! lsp-ui
  :load-path "~/Dev/Emacs/lsp-ui"
  :commands lsp-ui-mode
  :config
  (setq
   lsp-ui-sideline-enable nil
   lsp-ui-sideline-ignore-duplicate t
   lsp-ui-doc-header nil
   lsp-ui-doc-include-signature nil
   lsp-ui-doc-background (doom-color 'base4)
   lsp-ui-doc-border (doom-color 'fg)

   lsp-ui-peek-force-fontify nil
   lsp-ui-peek-expand-function (lambda (xs) (mapcar #'car xs)))

                                        ;(setq lsp-eldoc-hook '(lsp-document-highlight +my/hover-or-signature-help))

  (custom-set-faces
   '(ccls-sem-global-variable-face ((t (:underline t :weight extra-bold))))
   '(lsp-face-highlight-read ((t (:background "sea green"))))
   '(lsp-face-highlight-write ((t (:background "brown4"))))
   '(lsp-ui-sideline-current-symbol ((t (:foreground "grey38" :box nil))))
   '(lsp-ui-sideline-symbol ((t (:foreground "grey30" :box nil)))))

  (map! :after lsp-ui-peek
        :map lsp-ui-peek-mode-map
        "h" #'lsp-ui-peek--select-prev-file
        "j" #'lsp-ui-peek--select-next
        "k" #'lsp-ui-peek--select-prev
        "l" #'lsp-ui-peek--select-next-file
        )

  (defhydra hydra/ref (evil-normal-state-map "x")
    "reference"
    ("p" (-let [(i . n) (lsp-ui-find-prev-reference)]
           (if (> n 0) (message "%d/%d" i n))) "prev")
    ("n" (-let [(i . n) (lsp-ui-find-next-reference)]
           (if (> n 0) (message "%d/%d" i n))) "next")
    ("R" (-let [(i . n) (lsp-ui-find-prev-reference '(:role 8))]
           (if (> n 0) (message "read %d/%d" i n))) "prev read" :bind nil)
    ("r" (-let [(i . n) (lsp-ui-find-next-reference '(:role 8))]
           (if (> n 0) (message "read %d/%d" i n))) "next read" :bind nil)
    ("W" (-let [(i . n) (lsp-ui-find-prev-reference '(:role 16))]
           (if (> n 0) (message "write %d/%d" i n))) "prev write" :bind nil)
    ("w" (-let [(i . n) (lsp-ui-find-next-reference '(:role 16))]
           (if (> n 0) (message "write %d/%d" i n))) "next write" :bind nil)
    )
  )

(setq magit-repository-directories '(("~/Dev" . 2)))

(after! ivy
  (setq ivy-initial-inputs-alist nil)
  (push '(+ivy/switch-workspace-buffer) ivy-display-functions-alist)
  )

(after! quickrun
  (quickrun-add-command "c++/c1z"
    '((:command . "clang++")
      (:exec    . ("%c -std=c++1z %o -o %e %s"
                   "%e %a"))
      (:remove  . ("%e")))
    :default "c++"))

(after! realgud
  (setq realgud-safe-mode nil)
  (evil-collection-define-key 'normal 'realgud:shortkey-mode-map
    "d" #'realgud:cmd-newer-frame
    "D" #'realgud:cmd-delete
    "u" #'realgud:cmd-older-frame
    )
  )

(defun +advice/xref-set-jump (&rest args)
  (lsp-ui-peek--with-evil-jumps (evil-set-jump)))
(advice-add '+lookup/definition :before #'+advice/xref-set-jump)
(advice-add '+lookup/references :before #'+advice/xref-set-jump)


(defvar +my/xref-blacklist nil
  "List of paths that should not enable xref-find-* or dumb-jump-go")

;;; Override
;; This function is transitively called by xref-find-{definitions,references,apropos}
(after! xref
  ;; This is required to make `xref-find-references' not give a prompt.
  ;; `xref-find-references' asks the identifier (which has no text property)
  ;; and then passes it to `lsp-mode', which requires the text property at
  ;; point to locate the references.
  ;; https://debbugs.gnu.org/cgi/bugreport.cgi?bug=29619
  (setq xref-prompt-for-identifier '(not xref-find-definitions
                                         xref-find-definitions-other-window
                                         xref-find-definitions-other-frame
                                         xref-find-references))

  (defun xref--show-xrefs (xrefs display-action &optional always-show-list)
    ;; PATCH
    (lsp-ui-peek--with-evil-jumps (evil-set-jump))

    ;; PATCH Jump to the first candidate
    (if (not (cdr xrefs))
        (xref--pop-to-location (car xrefs) display-action)
      (funcall xref-show-xrefs-function xrefs
               `((window . ,(selected-window))))
      ))
  )

(after! ivy-xref
  ;; (defun ivy-xref-show-xrefs (xrefs alist)
  ;;   (minibuffer-with-setup-hook #'hydra-ivy/body
  ;;      (minibuffer-with-setup-hook #'ivy-toggle-calling
  ;;        (ivy-read "xref: " (ivy-xref-make-collection xrefs)
  ;;                  :require-match t
  ;;                  :action #'(lambda (candidate)
  ;;                              (xref--show-location (cdr candidate) 'quit))))))
  ;; (push '(xref-find-references) ivy-display-functions-alist)
  (push '(ivy-xref-show-xrefs . nil) ivy-sort-functions-alist)
  )

(def-package! rust-mode
  :mode "\\.rs$"
  :config
  (map! :map rust-mode-map
        :leader
        :n "=" #'rust-format-buffer
        )
  )

(def-package! smart-forward)

(def-package! symbol-overlay
  :commands (symbol-overlay-put))

(def-package! lsp-rust
  :defer t
  :init (add-hook 'rust-mode-hook #'lsp-rust-enable)
  :config
  )

(after! projectile
  (setq compilation-read-command nil)  ; no prompt in projectile-compile-project
  ;; . -> Build
  (projectile-register-project-type 'cmake '("CMakeLists.txt")
                                    :configure "cmake %s"
                                    :compile "cmake --build Debug"
                                    :test "ctest")
  (add-to-list 'projectile-globally-ignored-directories ".ccls-cache")
  )

(after! counsel-projectile
  (ivy-add-actions
   'counsel-projectile-switch-project
   `(("b" counsel-projectile-switch-project-action-switch-to-buffer
      "jump to a project buffer")
     ("s" counsel-projectile-switch-project-action-save-all-buffers
      "save all project buffers")
     ("k" counsel-projectile-switch-project-action-kill-buffers
      "kill all project buffers")
     ("c" counsel-projectile-switch-project-action-compile
      "run project compilation command")
     ("e" counsel-projectile-switch-project-action-edit-dir-locals
      "edit project dir-locals")
     ("v" counsel-projectile-switch-project-action-vc
      "open project in vc-dir / magit / monky")
     ("xe" counsel-projectile-switch-project-action-run-eshell
      "invoke eshell from project root")
     ("xt" counsel-projectile-switch-project-action-run-term
      "invoke term from project root")
     ("_" counsel-projectile-switch-project-action-org-capture
      "org-capture into project"))))

(def-package! rg)

(def-package! smartparens
  :config
  (setq sp-autoinsert-pair nil
        sp-autodelete-pair nil
        sp-escape-quotes-after-insert nil)
  (setq-default sp-autoskip-closing-pair nil)
  )

(def-package! tldr
  :commands (tldr)
  :config
  (setq tldr-directory-path (concat doom-etc-dir "tldr/"))
  (set-popup-rule! "^\\*tldr\\*" :side 'right :select t :quit t)
  )

(after! nav-flash
  ;; (defun nav-flash-show (&optional pos end-pos face delay)
  ;; ...
  ;; (let ((inhibit-point-motion-hooks t))
  ;; (goto-char pos)
  ;; (beginning-of-visual-line) ; work around args-out-of-range error when the target file is not opened
  (defun +advice/nav-flash-show (orig-fn &rest args)
    (ignore-errors (apply orig-fn args)))
  (advice-add 'nav-flash-show :around #'+advice/nav-flash-show))

(set-popup-rules! '(
  ("^\\*helpful" :size 0.4)
  ("^\\*info.*" :size 80 :size right)
  ("^\\*Man.*" :size 80 :side right)
  ))

;; TODO workaround emacsclient -nw a.cc
(advice-add #'+doom-dashboard|make-frame :override #'ignore)

(let ((profile "~/.config/doom/profile.el"))
  (when (file-exists-p profile)
    (load-file profile)))
