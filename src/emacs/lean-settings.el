;; Copyright (c) 2014 Microsoft Corporation. All rights reserved.
;; Released under Apache 2.0 license as described in the file LICENSE.
;;
;; Author: Soonho Kong
;;

(require 'cl-lib)

(defgroup lean nil
  "Lean Theorem Prover"
  :prefix "lean-"
  :group 'languages
  :link '(url-link :tag "Website" "http://leanprover.github.io")
  :link '(url-link :tag "Github"  "https://github.com/leanprover/lean"))

(defgroup lean-keybinding nil
  "Keybindings for lean-mode."
  :prefix "lean-"
  :group 'lean)

(defvar-local lean-default-executable-name
  (cl-case system-type
    ('gnu          "lean")
    ('gnu/linux    "lean")
    ('gnu/kfreebsd "lean")
    ('darwin       "lean")
    ('ms-dos       "lean")
    ('windows-nt   "lean.exe")
    ('cygwin       "lean.exe"))
  "Default executable name of Lean")

(defcustom lean-rootdir nil
  "Full pathname of lean root directory. It should be defined by user."
  :group 'lean
  :type 'string)

(defcustom lean-executable-name lean-default-executable-name
  "Name of lean executable"
  :group 'lean
  :type 'string)

(defcustom lean-company-use t
  "Use company mode for lean."
  :group 'lean
  :type 'boolean)

(defcustom lean-company-type-foreground (face-foreground 'font-lock-keyword-face)
  "Color of type parameter in auto-complete candidates"
  :group 'lean
  :type 'color)

(defcustom lean-eldoc-use t
  "Use eldoc mode for lean."
  :group 'lean
  :type 'boolean)

(defcustom lean-eldoc-nay-retry-time 0.3
  "When eldoc-function had nay, try again after this amount of time."
  :group 'lean
  :type 'number)

(defcustom lean-flycheck-use t
  "Use flycheck for lean."
  :group 'lean
  :type 'boolean)

(defcustom lean-flycheck-max-messages-to-display 100
  "Maximum number of flycheck messages to displaylean-flychecker checker name
   (Restart required to be effective)"
  :group 'lean
  :type 'number)

(defcustom lean-default-pp-width 120
  "Width of Lean error/warning messages"
  :group 'lean
  :type 'number)

(defcustom lean-flycheck-msg-width nil
  "Width of Lean error/warning messages"
  :group 'lean
  :type '(choice (const   :tag "Let lean-mode automatically detect this" nil)
                 (integer :tag "Specify the value and force lean-mode to use")))

(defcustom lean-delete-trailing-whitespace nil
  "Set this variable to true to automatically delete trailing
whitespace when a buffer is loaded from a file or when it is
written."
  :group 'lean
  :type 'boolean)

(defcustom lean-debug-mode-line '(:eval (lean-debug-mode-line-status-text))
  "Mode line lighter for Lean debug mode."
  :group 'lean
  :type 'sexp
  :risky t)

(defcustom lean-show-type-add-to-kill-ring nil
  "If it is non-nil, add the type information to the kill-ring so
that user can yank(paste) it later. By default, it's
false (nil)."
  :group 'lean
  :type 'boolean)

(defcustom lean-proofstate-display-style 'show-first-and-other-conclusions
  "Choose how to display proof state in *lean-info* buffer."
  :group 'lean
  :type '(choice (const :tag "Show all goals" show-all)
                 (const :tag "Show only the first" show-first)
                 (const :tag "Show the first goal, and the conclusions of all other goals" show-first-and-other-conclusions)))

(defcustom lean-keybinding-std-exe1 (kbd "C-c C-x")
  "Lean Keybinding for std-exe #1"
  :group 'lean-keybinding :type 'key-sequence)
(defcustom lean-keybinding-std-exe2 (kbd "C-c C-l")
  "Lean Keybinding for std-exe #2"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-show-key (kbd "C-c C-k")
  "Lean Keybinding for show-key"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-set-option (kbd "C-c C-o")
  "Lean Keybinding for set-option"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-eval-cmd (kbd "C-c C-e")
  "Lean Keybinding for eval-cmd"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-server-restart (kbd "C-c C-r")
  "Lean Keybinding for server-restart"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-find-definition (kbd "M-.")
  "Lean Keybinding for find-definition"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-tab-indent-or-complete (kbd "TAB")
  "Lean Keybinding for tab-indent-or-complete"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-lean-show-goal-at-pos (kbd "C-c C-g")
  "Lean Keybinding for show-goal-at-pos"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-lean-show-id-keyword-info (kbd "C-c C-p")
  "Lean Keybinding for show-id-keyword-info"
  :group 'lean-keybinding  :type 'key-sequence)
(defcustom lean-keybinding-lean-next-error-mode (kbd "C-c C-n")
  "Lean Keybinding for lean-next-error-mode"
  :group 'lean-keybinding  :type 'key-sequence)
(provide 'lean-settings)
