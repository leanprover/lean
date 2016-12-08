(setq inhibit-startup-screen t)

(if (getenv "LEAN_ROOTDIR")
    (setq lean-rootdir (getenv "LEAN_ROOTDIR"))
    (error "LEAN_ROOTDIR environment variable must be set"))

(if (getenv "LEAN_EMACS_PATH")
    (setq-local lean-emacs-path (getenv "LEAN_EMACS_PATH"))
    (error "LEAN_EMACS_PATH environment variable must be set"))

(setq lean-logo
      (condition-case nil
          (create-image (format "%s/lean.pgm" lean-emacs-path))
        (error nil)))

(setq lean-required-packages '(company dash dash-functional f
                               flycheck let-alist s seq unicode-fonts))

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(package-initialize)
(let ((need-to-refresh t))
  (dolist (p lean-required-packages)
    (when (not (package-installed-p p))
      (when need-to-refresh
        (package-refresh-contents)
        (setq need-to-refresh nil))
      (package-install p))))

; This enables out-of-the-box support for characters such as ℕ at least on Windows.
(require 'unicode-fonts)
(unicode-fonts-setup)

(setq load-path (cons lean-emacs-path load-path))

(require 'lean-mode)

(defun lean-welcome ()
  (let ((cbuf (current-buffer))
        (buf (get-buffer-create "Lean Welcome"))
        (cpoint (point-min)))
    (set-buffer buf)
    (setq fill-column (window-width))
    (if buffer-read-only (toggle-read-only))
    (erase-buffer)
    (insert "\n\n")
    (insert "           ")
    (when lean-logo (insert-image lean-logo))
    (setq cpoint (1+ (point)))
    (insert "\n")
    (insert "\n\nPlease check our website periodically for news of later versions")
    (insert "\nat http://leanprover.github.io")
    (insert "\n\nBug reports and suggestions for improvement should be posted at")
    (insert "\nhttps://github.com/leanprover/lean/issues")
    (insert "\n\nTo start using Lean, open a .lean file")
    (set-buffer-modified-p nil)
    (text-mode)
    (toggle-read-only)
    (goto-char (point-min))
    (switch-to-buffer buf)
    (set-buffer cbuf)
    buf))

(lean-welcome)
