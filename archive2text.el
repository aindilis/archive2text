;; this has to work with dired mode

(load-library "dired")
(global-set-key "\C-ca2t" 'archive2text)
(global-set-key "\C-ct2a" 'text2archive)

(defvar archive2text-export-method "xdg-open")

(defun archive2text ()
 ""
 (interactive)
 (let* ((output-file "/dev/shm/archive2text.txt")
	;; (taps (get-marked-files t current-prefix-arg))
	;; (tap (first taps))
	(tap (file-chase-links (dired-get-filename)))
	(file-or-directory (or
			    (if (kmax-directory-exists-p tap) 'directory)
			    (if (kmax-file-exists-p tap) 'file)
			    ))
	(tmp-type (kmax-file-type tap))
	(type
	 (progn
	  (see tmp-type 0.1)
	  (cond
	   ((equal file-or-directory 'directory) "directory")
	   ((string= tmp-type "POSIX tar archive (GNU)") "tar")
	   (t tmp-type)
	   )
	  )
	 )
	)
  (see
   (shell-command-to-string
    (see
     (join " "
      (list
       "/var/lib/myfrdcsa/codebases/minor/archive2text/scripts/archive2text"
       "--direction" "archive2text"
       "--use-redaction" "t"
       "--archive-or-dir" (shell-quote-argument tap)
       "--type" type
       "--text" output-file 
       ))
     0.1))
   0.1)
  (cond
   ((string= archive2text-export-method "xdg-open") (async-shell-command (concat "xdg-open " (shell-quote-argument output-file))))
   ((string= archive2text-export-method "gptel") (progn (ffap output-file) (end-of-buffer)))
   ((string= archive2text-export-method "llm-api") (kmax-not-yet-implemented))
   )))

(defun kmax-directory-exists-p (file)
 (interactive)
 (file-directory-p file))

(defun kmax-file-exists-p (file)
 ""
 (interactive)
 (file-exists-p file))

(defun kmax-file-type (argument-arg)
 ""
 (interactive)
 (let* ((output1 (shell-command-to-string (concat "file " (shell-quote-argument argument-arg))))
	(output2 (chomp output1))
	(output3 (kmax-extract-match "^.*?: \\(.*\\)$" output2 1)))
  (see output3)))

(defun kmax-extract-match (regex string &optional n)
 (string-match regex string)
 (match-string (or n 0) string))

(defun chomp (str)
 ;; from http://www.emacswiki.org/emacs/ElispCookbook                                                                                                                                                                                                                                                                                                                                                                                     
 "..."
 (let ((s (if (symbolp str)(symbol-name str) str)))
  (save-excursion
   (while (and
           (not (null (string-match "^\\( \\|\f\\|\t\\|\n\\)" s)))
           (> (length s) (string-match "^\\( \\|\f\\|\t\\|\n\\)" s)))
    (setq s (replace-match "" t nil s)))
   (while (and
           (not (null (string-match "\\( \\|\f\\|\t\\|\n\\)$" s)))
           (> (length s) (string-match "\\( \\|\f\\|\t\\|\n\\)$" s)))
    (setq s (replace-match "" t nil s))))
  s))
