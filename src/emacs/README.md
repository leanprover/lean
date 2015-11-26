Emacs mode for [lean theorem prover][Lean]

[lean]: https://github.com/leanprover/lean


Requirements
============

``lean-mode`` requires [Emacs 24][emacs24] and the following
packages, which can be installed via <kbd>M-x package-install</kbd>.

 - [dash][dash]
 - [dash-functional][dash]
 - [f][f]
 - [s][s]

[emacs24]: http://www.gnu.org/software/emacs
[dash]: https://github.com/magnars/dash.el
[f]: https://github.com/rejeep/f.el
[s]: https://github.com/magnars/s.el

The following packages are *optional*, but we recommend installing them
to use full features of ``lean-mode``.

 - [company][company]
 - [flycheck][flycheck]
 - [fill-column-indicator][fci]
 - [lua-mode][lua-mode]
 - [mmm-mode][mmm-mode]

Both the optional and required packages will be installed for you
automatically the first time you use ``lean-mode``, if you follow the
installation instructions below.

[company]: http://company-mode.github.io/
[flycheck]: http://flycheck.readthedocs.org/en/latest
[fci]: https://github.com/alpaker/Fill-Column-Indicator
[lua-mode]: http://immerrr.github.io/lua-mode/
[mmm-mode]: https://github.com/purcell/mmm-mode


Installation
============

When Emacs is started, it loads startup information from a special
initialization file, often called an "init file." The init file can be
found in different places on different systems:

- Emacs will check for a file named ``.emacs`` in your home directory.
- With GNU Emacs, it is common to use ``.emacs.d/init.el`` instead.
- With Aquamacs, it is common to use ``~/Library/Preferences/Aquamacs Emacs/Preferences.el``.

On Windows, there are two additional complications: 

- It may be hard to figure out what Emacs considers to be your "home
  directory".
- The file explorer may not let you create a file named ``.emacs``,
  since it begins with a period.

One solution is to run Emacs itself and create the file using C-c C-f
(control-C, control-F) and then entering ``~/.emacs``. (The tilde
indicates your home directory.) On Windows, you can also name the file
``_emacs``.
 
Put the following code in your Emacs init file:

```elisp
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)

;; Install required/optional packages for lean-mode
(defvar lean-mode-required-packages
  '(company dash dash-functional flycheck f
            fill-column-indicator s lua-mode mmm-mode))
(let ((need-to-refresh t))
  (dolist (p lean-mode-required-packages)
    (when (not (package-installed-p p))
      (when need-to-refresh
        (package-refresh-contents)
        (setq need-to-refresh nil))
      (package-install p))))
```

Then choose your installation method from the following scenarios, and
add the corresponding code to your init file:

Case 1: Build Lean from source
-----------------------------

```elisp
;; Set up lean-root path
(setq lean-rootdir "~/projects/lean")  ;; <=== YOU NEED TO MODIFY THIS
(setq-local lean-emacs-path
            (concat (file-name-as-directory lean-rootdir)
                    (file-name-as-directory "src")
                    "emacs"))
(add-to-list 'load-path (expand-file-name lean-emacs-path))
(require 'lean-mode)
```

Case 2: Install Lean via apt-get on Ubuntu or via dpkg on Debian
----------------------------------------------------------------

```elisp
;; Set up lean-root path
(setq lean-rootdir "/usr")
(setq-local lean-emacs-path "/usr/share/emacs/site-lisp/lean")
(add-to-list 'load-path (expand-file-name lean-emacs-path))
(require 'lean-mode)
```


Case 3: Install Lean via homebrew on OS X
-----------------------------------------

```elisp
;; Set up lean-root path
(setq lean-rootdir "/usr/local")
(setq-local lean-emacs-path "/usr/local/share/emacs/site-lisp/lean")
(add-to-list 'load-path (expand-file-name lean-emacs-path))
(require 'lean-mode)
```

Note: if you install homebrew in a custom location that is not the default
location, please run `brew info lean`, and it will tell you where the
lean-mode files are located. With that information, update the
`lean-emacs-path` variable accordingly.

Case 4: Install Lean in Windows
-------------------------------
```
;; Set up lean-root path
(setq lean-rootdir "\\lean-0.2.0-windows")
(setq-local lean-emacs-path "\\lean-0.2.0-windows\\share\\emacs\\site-lisp\\lean")
(add-to-list 'load-path (expand-file-name lean-emacs-path))
(require 'lean-mode)
```


Key Bindings
============

|Key                | Function                          |
|-------------------|-----------------------------------|
|<kbd>C-c C-x</kbd> | lean-std-exe                      |
|<kbd>C-c C-l</kbd> | lean-std-exe                      |
|<kbd>C-c C-t</kbd> | lean-eldoc-documentation-function |
|<kbd>C-c C-f</kbd> | lean-fill-placeholder             |
|<kbd>M-.</kbd>     | lean-find-tag                     |
|<kbd>TAB</kbd>     | lean-tab-indent-or-complete       |
|<kbd>C-c C-o</kbd> | lean-set-option                   |
|<kbd>C-c C-e</kbd> | lean-eval-cmd                     |


Known Issues and Possible Solutions
===================================

Unicode
-------

If you experience a problem rendering unicode symbols on emacs,
please download the following fonts and install them on your machine:

 - [Quivira.ttf](http://www.quivira-font.com/files/Quivira.ttf)
 - [Dejavu Fonts](http://sourceforge.net/projects/dejavu/files/dejavu/2.35/dejavu-fonts-ttf-2.35.tar.bz2)
 - [NotoSans](https://github.com/googlei18n/noto-fonts/blob/master/hinted/NotoSans-Regular.ttc?raw=true)
 - [NotoSansSymbols](https://github.com/googlei18n/noto-fonts/blob/master/unhinted/NotoSansSymbols-Regular.ttf?raw=true)

Then, have the following lines in your emacs setup to use `DejaVu Sans Mono` font:

```elisp
(when (member "DejaVu Sans Mono" (font-family-list))
  (set-face-attribute 'default nil :font "DejaVu Sans Mono-11"))
```

You may also need to install [emacs-unicode-fonts](https://github.com/rolandwalker/unicode-fonts) package.

 - Run `M-x package-refresh-contents`, `M-x package-install`, and type `unicode-fonts`.
 - Add the following lines in your emacs setup:

   ```lisp
(require 'unicode-fonts)
(unicode-fonts-setup)
   ```


Contributions
=============

Contributions are welcome!

If your contribution is a bug fix, create your topic branch from
`master`. If it is a new feature, check if there exists a
WIP(work-in-progress) branch (`vMAJOR.MINOR-wip`). If it does, use
that branch, otherwise use `master`.

Install [Cask](https://github.com/cask/cask) if you haven't already,
then:

    $ cd /path/to/lean/src/emacs
    $ cask

Run all tests with:

    $ make
