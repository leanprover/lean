;; -*- lexical-binding: t; -*-
;; Copyright (c) 2014 Microsoft Corporation. All rights reserved.
;; Released under Apache 2.0 license as described in the file LICENSE.
;;
;; Author: Soonho Kong
;;
(require 'cl-lib)
(require 'dash)
(require 'dash-functional)
(require 's)
(require 'lean-util)
(require 'lean-debug)

;; Type Information
;; ----------------
(defun lean-info-type-kind (typeinfo)
  (cl-first typeinfo))
(defun lean-info-type-p (typeinfo)
  (pcase typeinfo
    (`TYPE t)
    ((pred stringp) (string-prefix-p "-- TYPE" typeinfo))
    ((pred listp) (and (lean-info-type-p (cl-first typeinfo))))))
(defun lean-info-type-pos (typeinfo)
  (cl-second typeinfo))
(defun lean-info-type-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-type-parse (seq)
  (when (lean-info-type-p seq)
    (let ((header (lean-info-type-parse-header (car seq)))
          (body (cdr seq)))
      `(TYPE ,header ,body))))
(defun lean-info-type-body (typeinfo)
  (cl-third typeinfo))
(defun lean-info-type-body-str (typeinfo)
  (s-join "\n" (lean-info-type-body typeinfo)))

;; Overload Information
;; --------------------
(defun lean-info-overload-type (overload)
  (cl-first overload))
(defun lean-info-overload-p (overload)
  (pcase overload
    (`OVERLOAD t)
    ((pred stringp) (string-prefix-p "-- OVERLOAD" overload))
    ((pred listp) (and (lean-info-overload-p (cl-first overload))))))
(defun lean-info-overload-pos (overload)
  (cl-second overload))
(defun lean-info-overload-names (overload)
  (cl-loop for seq in (cl-third overload)
           collect (s-join "\n" seq)))
(defun lean-info-overload-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-overload-parse (seq)
  (when (lean-info-overload-p seq)
    (let ((header (lean-info-overload-parse-header (car seq)))
          (body (-split-on "--" (cdr seq))))
      `(OVERLOAD ,header ,body))))

;; Synth Information
;; ----------------
(defun lean-info-synth-type (synth)
  (cl-first synth))
(defun lean-info-synth-p (synth)
  (pcase synth
    (`SYNTH t)
    ((pred stringp) (string-prefix-p "-- SYNTH" synth))
    ((pred listp) (and (lean-info-synth-p (cl-first synth))))))
(defun lean-info-synth-pos (synth)
  (cl-second synth))
(defun lean-info-synth-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-synth-parse (seq)
  (when (lean-info-synth-p seq)
    (let ((header (lean-info-synth-parse-header (car seq)))
          (body (cdr seq)))
      `(SYNTH ,header ,body))))
(defun lean-info-synth-body (synth)
  (cl-third synth))
(defun lean-info-synth-body-str (synth)
  (s-join "\n" (lean-info-synth-body synth)))

;; Coercion Information
;; ----------------
(defun lean-info-coercion-type (coercion)
  (cl-first coercion))
(defun lean-info-coercion-p (coercion)
  (pcase coercion
    (`COERCION t)
    ((pred stringp) (string-prefix-p "-- COERCION" coercion))
    ((pred listp) (and (lean-info-coercion-p (cl-first coercion))))))
(defun lean-info-coercion-pos (coercion)
  (cl-second coercion))
(defun lean-info-coercion-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-coercion-parse (seq)
  (when (lean-info-coercion-p seq)
    (let* ((header (lean-info-coercion-parse-header (car seq)))
           (body (-split-on  "--" (cdr seq)))
           (coerced-expr (cl-first body))
           (coerced-type (cl-second body)))
      `(COERCION ,header ,coerced-expr ,coerced-type))))
(defun lean-info-coercion-expr (coercion)
  (cl-third coercion))
(defun lean-info-coercion-expr-str (coercion)
  (s-join "\n" (lean-info-coercion-expr coercion)))
(defun lean-info-coercion-type (coercion)
  (cl-fourth coercion))
(defun lean-info-coercion-type-str (coercion)
  (s-join "\n" (lean-info-coercion-type coercion)))

;; Extra Information
;; ----------------
(defun lean-info-extra-type (extra)
  (cl-first extra))
(defun lean-info-extra-p (extra)
  (pcase extra
    (`EXTRA t)
    ((pred stringp) (string-prefix-p "-- EXTRA_TYPE" extra))
    ((pred listp) (and (lean-info-extra-p (cl-first extra))))))
(defun lean-info-extra-pos (extra)
  (cl-second extra))
(defun lean-info-extra-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-extra-parse (seq)
  (when (lean-info-extra-p seq)
    (let* ((header (lean-info-extra-parse-header (car seq)))
           (body (-split-on  "--" (cdr seq)))
           (coerced-expr (cl-first body))
           (coerced-type (cl-second body)))
      `(EXTRA ,header ,coerced-expr ,coerced-type))))
(defun lean-info-extra-expr (extra)
  (cl-third extra))
(defun lean-info-extra-expr-str (extra)
  (s-join "\n" (lean-info-extra-expr extra)))
(defun lean-info-extra-type (extra)
  (cl-fourth extra))
(defun lean-info-extra-type-str (extra)
  (s-join "\n" (lean-info-extra-type extra)))

;; Identifier Information
;; ----------------------
(defun lean-info-identifier-type (identifier)
  (cl-first identifier))
(defun lean-info-identifier-p (identifier)
  (pcase identifier
    (`IDENTIFIER t)
    ((pred stringp) (string-prefix-p "-- IDENTIFIER" identifier))
    ((pred listp) (and (lean-info-identifier-p (cl-first identifier))))))
(defun lean-info-identifier-pos (identifier)
  (cl-second identifier))
(defun lean-info-identifier-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-identifier-parse (seq)
  (when (lean-info-identifier-p seq)
    (let ((header (lean-info-identifier-parse-header (car seq)))
          (body (cdr seq)))
      `(IDENTIFIER ,header ,body))))
(defun lean-info-identifier-body (identifier)
  (cl-third identifier))
(defun lean-info-identifier-body-str (identifier)
  (s-join "\n" (lean-info-identifier-body identifier)))


;; Symbol Information
;; ----------------
(defun lean-info-symbol-type (symbol)
  (cl-first symbol))
(defun lean-info-symbol-p (symbol)
  (pcase symbol
    (`SYMBOL t)
    ((pred stringp) (string-prefix-p "-- SYMBOL" symbol))
    ((pred listp) (and (lean-info-symbol-p (cl-first symbol))))))
(defun lean-info-symbol-pos (symbol)
  (cl-second symbol))
(defun lean-info-symbol-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-symbol-parse (seq)
  (when (lean-info-symbol-p seq)
    (let ((header (lean-info-symbol-parse-header (car seq)))
          (body (cdr seq)))
      `(SYMBOL ,header ,body))))
(defun lean-info-symbol-body (symbol)
  (cl-third symbol))
(defun lean-info-symbol-body-str (symbol)
  (s-join "\n" (lean-info-symbol-body symbol)))

(defun lean-info-id-symbol-body-str (info)
  (cl-case (lean-info-kind info)
    ('IDENTIFIER (s-join "\n" (lean-info-symbol-body info)))
    ('SYMBOL     (s-join "\n" (lean-info-identifier-body info)))))


;; Proofstate Information
;; --------------------
(defun lean-info-proofstate-type (proofstate)
  (cl-first proofstate))
(defun lean-info-proofstate-p (proofstate)
  (pcase proofstate
    (`PROOF_STATE t)
    ((pred stringp) (string-prefix-p "-- PROOF_STATE" proofstate))
    ((pred listp) (and (lean-info-proofstate-p (cl-first proofstate))))))
(defun lean-info-proofstate-pos (proofstate)
  (cl-second proofstate))
(defun lean-info-proofstate-parse-header (str)
  (let ((items (split-string str "|")))
    (list (string-to-number (cl-second items))
          (string-to-number (cl-third items)))))
(defun lean-info-proofstate-parse (seq)
  (when (lean-info-proofstate-p seq)
    (let ((header (lean-info-proofstate-parse-header (car seq)))
          (body (-split-on "--" (cdr seq))))
      `(PROOF_STATE ,header ,body)
      )))
(defun lean-info-proofstate-states (proofstate)
  (cl-third proofstate))
(defun lean-info-proofstate-state-str (string-seq)
  (s-join "\n" string-seq))
(defun lean-info-proofstate-extract-conclusion (string-seq)
  (--drop-while (not (s-starts-with? "⊢" it)) string-seq))
(defun lean-info-proofstate-extract-premises (string-seq)
  (--take-while (not (s-starts-with? "⊢" it)) string-seq))
(defun lean-info-proofstate-states-str (proofstate &optional display-style)
  (let* ((states (lean-info-proofstate-states proofstate))
         (first-state (-first-item states))
         (rest-states (cdr states))
         (display-style (or display-style lean-proofstate-display-style)))
    (cond
     (first-state
      (pcase display-style
        (`show-all
         (s-join
          "\n\n"
          (-map 'lean-info-proofstate-state-str states)))
        (`show-first
         (lean-info-proofstate-state-str first-state))
        (`show-first-and-other-conclusions
         (s-join
          "\n\n"
          (-map 'lean-info-proofstate-state-str
                (cons first-state (-map
                                   'lean-info-proofstate-extract-conclusion
                                   rest-states)))))))
     (t "No Goal"))))

;; Basic
;; -----
(defun lean-info-kind (info)
  (cl-first info))
(defun lean-info-nay-p (str)
  (when (string-match (rx "-- BEGININFO " (* not-newline) "NAY") str)
    t))
(defun lean-info-stale-p (str)
  (when (string-match (rx "-- BEGININFO " (* not-newline) "STALE") str)
    t))
(defun lean-info-pos (info)
  (cl-case (lean-info-kind info)
    (TYPE        (lean-info-type-pos       info))
    (OVERLOAD    (lean-info-overload-pos   info))
    (SYNTH       (lean-info-synth-pos      info))
    (COERCION    (lean-info-coercion-pos   info))
    (IDENTIFIER  (lean-info-identifier-pos info))
    (SYMBOL      (lean-info-symbol-pos     info))
    (EXTRA       (lean-info-extra-pos      info))
    (PROOF_STATE (lean-info-proofstate-pos info))))
(defun lean-info-line-number (info)
  (cl-first (lean-info-pos info)))
(defun lean-info-column (info)
  (cl-second (lean-info-pos info)))

;; Info Parsing
;; ================
(defun lean-info-list-split (str)
  "Parse string into list of list of strings.

Take out \"BEGININFO\" and \"ENDINFO\" and Use \"ACK\" as a delim."
  (-split-on "-- ACK"
             (--filter (not (or (string-prefix-p "-- BEGININFO" it)
                                (string= "-- ENDINFO" it)))
                       (split-string str "\n"))))

(defun lean-info-list-parse-string (str)
  "Parse string into info-list"
  (let ((string-seq-seq (lean-info-list-split str))
        result)
    (cl-loop for string-seq in string-seq-seq
             when string-seq
             do (setq result
                      (or (lean-info-type-parse string-seq)
                          (lean-info-overload-parse string-seq)
                          (lean-info-synth-parse string-seq)
                          (lean-info-coercion-parse string-seq)
                          (lean-info-identifier-parse string-seq)
                          (lean-info-symbol-parse string-seq)
                          (lean-info-extra-parse string-seq)
                          (lean-info-proofstate-parse string-seq)))
             when result
             collect result)))

(defun lean-info-list-filter (info-list start-column)
  "Given a info-list, only return an info-item is NAY or whose start-column is matched with the argument."
  (--filter (let ((col (lean-info-column it)))
              (and col (= start-column col)))
            info-list))

(defun lean-get-partial-names (full-name)
  "Given a full-name \"a.b.c.d\", return a set of partial names (\"a.b.c.d\" \"b.c.d\" \"c.d\" \"d\")"
  (cl-labels ((helper(l1 l2 names)
                     (cond (l1 (helper
                                (-butlast l1)
                                (cons nil (-butlast l2))
                                (-zip-with (lambda (x y) (if y (concat x "." y) x))
                                           names
                                           (cons nil (-butlast l2)))))
                           (t (reverse names)))))
    (let ((items (reverse (split-string full-name "\\."))))
      (helper items items items))))

(defun lean-match-name-at-pos (file-name line-number column-number name)
  "Return t if there is name at pos in a file."
  ;; Try to use a existing buffer if there is one
  (let ((buffer (flymake-find-buffer-for-file file-name))
        str pos)
    (unless buffer
      ;; In case a user haven't opened the file before, we read the
      ;; file to the temp buffer (*lean-server-temp*) and proceed.
      (setq buffer (get-buffer-create "*lean-server-temp*"))
      (with-current-buffer buffer
        (erase-buffer)
        (insert-file-contents file-name)))
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (forward-line (1- line-number))
        (forward-char column-number)
        (setq pos (point))
        (setq str (buffer-substring-no-properties pos
                                                  (min (+ pos (length name))
                                                       (point-max))))
        (string= name str)))))

(defun lean-match-full-name-at-pos (file-name line-number column-number full-name)
  "Return the matched name for the given full-name if any."
  (let ((partial-names (lean-get-partial-names full-name)))
    (--first (lean-match-name-at-pos file-name line-number column-number it) partial-names)))

(defun lean-info-list-find-start-column (info-list file-name column-number)
  "Find the start-column of the id/symbol in info-list at a file-name/column-number"

  ;; Extract symbol, ids
  (let* ((sorted-id-symbol-list
          (-sort (-on '< 'lean-info-column)
                 (--filter (or (lean-info-identifier-p it)
                               (lean-info-symbol-p it))
                           info-list)))
         ;; candidate = list of info
         (candidate-list
          (-last-item
           (-partition-by 'lean-info-column
                          (--filter (<= (lean-info-column it) column-number)
                                    sorted-id-symbol-list))))
         matched-name
         start-column
         full-name
         candidate)
    (setq candidate
          (-first (lambda (info)
                    (let* ((start-column (lean-info-column info))
                           (full-name (lean-info-id-symbol-body-str info))
                           (matched-name (lean-match-full-name-at-pos
                                          file-name
                                          (lean-info-line-number info)
                                          start-column
                                          full-name)))
                      (< column-number
                         (+ start-column (length matched-name)))))
                  candidate-list))
    (when candidate
      (lean-info-column candidate))))

(defun lean-info-list-parse (str &optional file-name column-number)
  "Parse input string and return info-list."
  (let ((info-list (lean-info-list-parse-string str))
        start-column)
    (cond
     ;; Proof State Case
     ((and column-number (or (looking-at ",")
                             (and
                              (looking-at (rx white))
                              (looking-back (rx "," (* white))))))
      ;; Find a position of "," and filter the info-list to extract proofstate info
      (lean-info-list-filter info-list
                             (save-excursion
                               (unless (looking-at ",")
                                 (search-backward ","))
                               (current-column))))
     ;; When file-name/column-number is specified, try to start-column of id/symbol
     ((and file-name column-number)
      (setq start-column (lean-info-list-find-start-column info-list file-name column-number))
      (if start-column
          (lean-info-list-filter info-list start-column)
        ;; If there is no symbol at column-number, return nil
        nil))
     ;; When not specified, just return info-list.
     (t info-list))))

(cl-defstruct lean-info-record type overload synth coercion identifier symbol extra proofstate nay stale)

(defun lean-info-record-parse (string &optional file-name column-number)
  "Parse string into info-record"
  (let* ((info-list   (lean-info-list-parse string file-name column-number))
         (types       (-filter 'lean-info-type-p       info-list))
         (overloads   (-filter 'lean-info-overload-p   info-list))
         (synths      (-filter 'lean-info-synth-p      info-list))
         (coercions   (-filter 'lean-info-coercion-p   info-list))
         (identifiers (-filter 'lean-info-identifier-p info-list))
         (symbols     (-filter 'lean-info-symbol-p     info-list))
         (extras      (-filter 'lean-info-extra-p      info-list))
         (proofstates (-filter 'lean-info-proofstate-p info-list)))
    (make-lean-info-record :type       types
                           :overload   overloads
                           :synth      synths
                           :coercion   coercions
                           :identifier identifiers
                           :symbol     symbols
                           :extra      extras
                           :proofstate proofstates
                           :nay        (lean-info-nay-p   string)
                           :stale      (lean-info-stale-p string))))

(defun lean-info-record-to-strings (info-record)
  "Given typeinfo, overload, and sym-name, compose information as a list of strings."
  (let* ((type       (cl-first (lean-info-record-type       info-record)))
         (overload   (cl-first (lean-info-record-overload   info-record)))
         (synth      (cl-first (lean-info-record-synth      info-record)))
         (coercion   (cl-first (lean-info-record-coercion   info-record)))
         (extra      (cl-first (lean-info-record-extra      info-record)))
         (proofstate (cl-first (lean-info-record-proofstate info-record)))
         (id         (cl-first (lean-info-record-identifier info-record)))
         (sym        (cl-first (lean-info-record-symbol     info-record)))
         (stale      (lean-info-record-stale                info-record))
         name-str type-str coercion-str extra-str proofstate-str overload-str stale-str str)
    (setq name-str
          (cond
           (synth (lean-info-synth-body-str synth))
           ((and id sym)
            (format "[%s] %s"
                    (lean-info-id-symbol-body-str sym)
                    (lean-info-id-symbol-body-str id)))
           (id   (lean-info-id-symbol-body-str id))
           (sym  (lean-info-id-symbol-body-str sym))))
    (when coercion
      (setq coercion-str
            (format "%s : %s"
                    (propertize (lean-info-coercion-expr-str coercion) 'face 'font-lock-variable-name-face)
                    (lean-info-coercion-type-str coercion))))
    (when type
      (setq type-str (lean-info-type-body-str type)))
    (when (and name-str overload)
      (setq overload-str
            (s-join
	     ", "
	     (--remove
	      (or
	       (and id	(string-prefix-p (lean-info-id-symbol-body-str id) it))
	       (and sym (string-prefix-p (lean-info-id-symbol-body-str sym) it)))
	      (lean-info-overload-names overload)))))
    (when extra
      (setq str
            (cond (lean-show-only-type-in-parens (format ": %s" (lean-info-extra-type-str extra)))
                  (t (format "(%s) : %s"
                             (propertize (lean-info-extra-expr-str extra) 'face 'font-lock-variable-name-face)
                             (lean-info-extra-type-str extra))))))
    (when (and name-str type-str)
      (setq str (format "%s : %s"
                        (propertize name-str 'face 'font-lock-variable-name-face)
                        type-str)))
    (when (and str coercion-str)
      (setq str (format "%s\n%s %s"
                        str
                        (propertize "coercion applied" 'face 'font-lock-keyword-face)
                        coercion-str)))
    (when overload-str
      (setq str (concat str
                        (format "\n%s with %s"
                                (propertize "overloaded" 'face 'font-lock-keyword-face)
                                overload-str))))
    (when proofstate
      (setq str (lean-info-proofstate-states-str proofstate)))
    (when (and stale str)
      (setq stale-str (format "[%s]"
                              (propertize "stale" 'face '(foreground-color . "red")))))
    (cond (stale-str (list stale-str str))
          (t         (list str)))))

(defun lean-get-info-record-at-point-cont (info-record cont)
  (cond ((lean-info-record-nay info-record)
         (lean-debug "executing continucation for get-info-record-at-point %d: NAY DETECTED"
                            lean-global-nay-retry-counter)
         (setq lean-global-nay-retry-counter (1+ lean-global-nay-retry-counter))
         (if (and (< lean-global-nay-retry-counter
                     lean-global-nay-retry-counter-max)
                  (= (length lean-global-async-task-queue) 1))
             ;; Retry
             (lean-get-info-record-at-point cont)
           ;; Stop
           (setq lean-global-nay-retry-counter 0)))
        (t
         (lean-debug "executing continucation for get-info-record-at-point: OK")
         (setq lean-global-nay-retry-counter 0)
         (funcall cont info-record))))

(defun lean-get-begin-paren-pos ()
  (save-excursion
    (forward-char 1)
    (backward-list 1)
    `(,(line-number-at-pos) . ,(lean-line-offset))))

(defun lean-get-info-record-at-point (cont)
  "Get info-record at the current point"
  (let* ((file-name     (buffer-file-name))
         (line-number   (line-number-at-pos))
         (column-number (lean-line-offset))
         (cmd           (cond ((or (looking-at "(") (looking-at ","))
                               (lean-cmd-info line-number column-number))
                              ((and (eolp) (looking-back ",") (> column-number 1))
                               (lean-cmd-info line-number (1- column-number)))
                              (t (lean-cmd-info line-number)))))
    (lean-debug "get-info-record-at-point: %S" cmd)
    (lean-server-check-current-file file-name)
    (lean-server-send-cmd-async cmd (lambda (info-record)
                                      (lean-get-info-record-at-point-cont info-record
                                                                          cont)))))

(defun lean-get-full-name-at-point-cont (info-record)
  "Continuation of lean-get-full-name-at-point"
  (lean-debug "lean-get-full-name-at-point-cont: %S" info-record)
  (let ((id (cl-first (lean-info-record-identifier info-record))))
    (when id
      (lean-info-identifier-body-str id))))

(defun lean-get-full-name-at-point (cont)
  "Return the full-name at point (if any)"
  (lean-get-info-record-at-point
   (lambda (info-record)
     (lean-debug "lean-get-full-name-at-point: executing continuation for get-full-name-at-point")
     (funcall cont
              (lean-get-full-name-at-point-cont info-record)))))

(provide 'lean-info)
