;; -*- lexical-binding: t -*-

;;; mine

;; TODO: eval rx ?
;; TODO: C-x f b
(defun open-all-files-in-directory (&optional dir ext)
  (interactive)
  (mapc (lambda (x)
          (find-file x))
        (directory-files-no-dots-absolute
         (or dir
             (read-directory-name "Open all files in dir: ")))))

;;; from kf: make file exec for shell

;;;###autoload
(defun kf-make-file-executable ()
  "Make current buffer's file have permissions 755 \(rwxr-xr-x)\.
This will save the buffer if it is not currently saved."
  (interactive)
  (set-buffer-modified-p t)
  (save-buffer)
  (chmod (buffer-file-name) 493))

;; https://www.reddit.com/r/emacs/comments/10qo7vb/comment/j6rmvvf

;; TODO: fix
(defun open-on-github (&optional args)
  (interactive "P")
  (let
      ((repo-url (magit-git-string-ng "git remote get-url --push origin"))
       (commit-hash (magit-git-string-ng "git rev-parse HEAD"))
       (start-line (if (use-region-p)
                       (line-number-at-pos (region-beginning))
                     (line-number-at-pos)))
       (end-line (if (use-region-p) (line-number-at-pos (region-end)))))
    (unless repo-url (error  "not in a git repo"))
    (browse-url
     (concat
      (substring repo-url 0 -4)
      "/blob/"
      commit-hash
      "/"
      (substring buffer-file-name (length (project-root)))
      "#L" (number-to-string start-line)
      (if (and (use-region-p) (< 0 (- end-line start-line)))
          (concat "..L" (number-to-string end-line)))
      ))))

;;; from condy0919

(defun find-file--line-number (orig-fun filename
                                        &optional wildcards)
  "Turn files like file.js:14:10 into file.js and going to line 14, col 10."
  (save-match-data
    (let* ((matched (string-match
                     "^\\(.*?\\):\\([0-9]+\\):?\\([0-9]*\\)$"
                     filename))
           (line-number (and matched
                             (match-string 2 filename)
                             (string-to-number
                              (match-string 2 filename))))
           (col-number (and matched
                            (match-string 3 filename)
                            (string-to-number (match-string 3 filename))))
           (filename (if matched
                         (match-string 1 filename)
                       filename)))
      (apply orig-fun (list filename wildcards))
      (when line-number
        ;; goto-line is for interactive use
        (goto-char (point-min))
        (forward-line (1- line-number))
        (when (> col-number 0)
          (forward-char (1- col-number)))))))

;; TODO: does this function take directories into account/
;; does it work like +rename-current-file?
;; test then adapt and bind

;; from http://emacsredux.com/blog/2013/05/04/rename-file-and-buffer/

;;;###autoload
(defun redguardtoo-vc-rename-file-and-buffer ()
  "Rename the current buffer and file it is visiting."
  (interactive)
  (let* ((filename (buffer-file-name)))
    (cond
     ((not (and filename (file-exists-p filename)))
      (message "Buffer is not visiting a file!"))
     (t
      (let* ((new-name (read-file-name "New name: " filename)))
        (cond
         ((vc-backend filename) (vc-rename-file filename new-name))
         (t
          (rename-file filename new-name t)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil))))))))

;;;###autoload
(defun +rename-current-file (newname) ;; condy0919
  "Rename current visiting file to NEWNAME.
If NEWNAME is a directory, move file to it."
  (interactive
   (progn
     (unless buffer-file-name
       (user-error "No file is visiting"))
     (let ((name (read-file-name "Rename to: " nil buffer-file-name 'confirm)))
       (when (equal (file-truename name)
                    (file-truename buffer-file-name))
         (user-error "Can't rename file to itself"))
       (list name))))
  ;; NEWNAME is a directory
  (when (equal newname (file-name-as-directory newname))
    (setq newname (concat newname (file-name-nondirectory buffer-file-name))))
  (rename-file buffer-file-name newname)
  (set-visited-file-name newname)
  (rename-buffer newname))

;;;###autoload
(defun +delete-current-file (file)
  "Delete current visiting FILE."
  (interactive
   (list (or buffer-file-name
             (user-error "No file is visiting"))))
  (when (y-or-n-p (format "Really delete '%s'? " file))
    (kill-this-buffer)
    (delete-file file)))

;;;###autoload
(defun +rename-current-file (newname)
  "Rename current visiting file to NEWNAME.
If NEWNAME is a directory, move file to it."
  (interactive
   (progn
     (unless buffer-file-name
       (user-error "No file is visiting"))
     (let ((name (read-file-name "Rename to: " nil buffer-file-name 'confirm)))
       (when (equal (file-truename name)
                    (file-truename buffer-file-name))
         (user-error "Can't rename file to itself"))
       (list name))))
  ;; NEWNAME is a directory
  (when (equal newname (file-name-as-directory newname))
    (setq newname (concat newname (file-name-nondirectory buffer-file-name))))
  (rename-file buffer-file-name newname)
  (set-visited-file-name newname)
  (rename-buffer newname))

;;;###autoload
(defun +delete-current-file (file)
  "Delete current visiting FILE."
  (interactive
   (list (or buffer-file-name
             (user-error "No file is visiting"))))
  (when (y-or-n-p (format "Really delete '%s'? " file))
    (kill-this-buffer)
    (delete-file file)))

;; TODO: think and implement
;;;###autoload
(defun redguardtoo-vc-copy-file-and-rename-buffer ()
  "Copy the current buffer and file it is visiting.
If the old file is under version control, the new file is added into
version control automatically."
  (interactive)
  (let* ((filename (buffer-file-name)))
    (cond
     ((not (and filename (file-exists-p filename)))
      (message "Buffer is not visiting a file!"))
     (t
      (let* ((new-name (read-file-name "New name: " filename)))
        (copy-file filename new-name t)
        (rename-buffer new-name)
        (set-visited-file-name new-name)
        (set-buffer-modified-p nil)
        (when (vc-backend filename)
          (vc-register)))))))

;;;###autoload
(defun +copy-current-file (new-path &optional overwrite-p)
  "Copy current buffer's file to `NEW-PATH'.
If `OVERWRITE-P', overwrite the destination file without
confirmation."
  (interactive
   (progn
     (unless buffer-file-name
       (user-error "No file is visiting"))
     (list (read-file-name "Copy file to: ")
           current-prefix-arg)))
  (let ((old-path (buffer-file-name))
        (new-path (expand-file-name new-path)))
    (make-directory (file-name-directory new-path) t)
    (copy-file old-path new-path (or overwrite-p 1))))

;;;###autoload
(defun jf/nab-file-name-to-clipboard (parg)
  "Nab, I mean copy, the current buffer file name to the clipboard.

  The PARG is the universal prefix argument.

  If you pass no args, copy the filename with full path.
  If you pass one arg, copy the filename without path.
  If you pass two args, copy the path to the directory of the file."
  ;; https://blog.sumtypeofway.com/posts/emacs-config.html
  (interactive "P")
  (let* ((prefix (car parg))
         (raw-filename
          (if (equal major-mode 'dired-mode) default-directory (buffer-file-name)))
         (filename
          (cond
           ((not prefix)  raw-filename)
           ((= prefix 4)  (file-name-nondirectory raw-filename))
           ((= prefix 16) (file-name-directory raw-filename)))))
    (when filename
      (kill-new filename)
      (message "Copied buffer file name '%s' to the clipboard." filename))))

;;;###autoload
(defun +copy-current-buffer-name ()
  "Copy the name to the current buffer."
  (interactive)
  (message (kill-new (buffer-name))))

;;; from xah lee

;;;###autoload
(defun xah-open-file-from-clipboard ()
  "Open the file path from OS's clipboard.
The clipboard should contain a file path or url to xah site. Open that file in emacs.
Version 2017-03-21 2021-07-31"
  (interactive)
  (let (($input (with-temp-buffer (yank) (buffer-string)))
        $fpath )
    (if (string-match-p "\\`http://" $input)
        (progn
          (setq $fpath (xahsite-url-to-filepath $input "addFileName"))
          (if (file-exists-p $fpath) (find-file $fpath) (error "file doesn't exist 「%s」" $fpath)))
      (progn
        "not starting http://"
        (setq $input (xah-html-remove-uri-fragment $input))
        (setq $fpath (xahsite-web-path-to-filepath $input default-directory))
        (if (file-exists-p $fpath)
            (find-file $fpath)
          (user-error "file doesn't exist. 「%s」" $fpath))))))

;;; from TxGVNN: find-file rec in current dir. fzf in emacs

;;;###autoload
(defun find-file-rec ()
  "Find a file in the current working directory recursively."
  (interactive)
  (let ((find-files-program
         (cond
          ((executable-find "rg") '("rg" "--color=never" "--files"))
          ((executable-find "find") '("find" "-type" "f")))))
    (find-file
     (completing-read
      "Find file: " (apply #'process-lines find-files-program)))))

;;; from xc

;;;###autoload
(defun xc/rename-file-and-buffer (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME.

See URL `http://steve.yegge.googlepages.com/my-dot-emacs-file'"
  (interactive "GNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not filename)
        (message "Buffer '%s' is not visiting a file!" name)
      (if (get-buffer new-name)
          (message "A buffer named '%s' already exists!" new-name)
        (progn
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil))))))

;;;###autoload
(defun xc/backup-region-or-buffer (&optional buffer-or-name file beg end)
  "Write copy of BUFFER-OR-NAME between BEG and END to FILE.

BUFFER-OR-NAME is either a buffer object or name. Uses current
buffer when none is passed.  Uses entire buffer for region when
BEG and END are nil.  Prompts for filename when called
interactively.  Will always ask before overwriting. Returns the
name of the file written to.

See URL `https://stackoverflow.com/a/18780453/5065796'."
  (interactive)
  (let* ((buffer-or-name (or buffer-or-name (current-buffer)))
         (buffo (or (get-buffer buffer-or-name) (error "Buffer does not exist")))  ; buffer object
         (buffn (or (buffer-file-name buffo) (buffer-name buffo)))                 ; buffer name
         (beg (or beg (if (use-region-p) (region-beginning) beg)))
         (end (or end (if (use-region-p) (region-end) end)))
         (prompt (if (and beg end) "region" "buffer"))
         (new (if (called-interactively-p 'interactive)
                  (read-file-name
                   (concat "Write " prompt " to file: ")
                   nil nil nil
                   (and buffn (file-name-nondirectory buffn)))
                (or file (error "Filename cannot be nil"))))
         ;; See `write-region' for meaning of 'excl
         (mustbenew (if (and buffn (file-equal-p new buffn)) 'excl t)))
    (with-current-buffer buffo
      (if (and beg end)
          (write-region beg end new nil nil nil mustbenew)
        (save-restriction
          (widen)
          (write-region (point-min) (point-max) new nil nil nil mustbenew))))
    new))


;;; next file, previous file

;; https://emacs.stackexchange.com/questions/12153/does-some-command-exist-which-goes-to-the-next-file-of-the-current-directoryhttps://emacs.stackexchange.com/questions/12153/does-some-command-exist-which-goes-to-the-next-file-of-the-current-directory

;;;###autoload
(defun find-next-file (&optional backward)
  "Find the next file (by name) in the current directory.

With prefix arg, find the previous file."
  (interactive "P")
  (when buffer-file-name
    (let* ((file (expand-file-name buffer-file-name))
           (files (cl-remove-if (lambda (file) (cl-first (file-attributes file)))
                                (sort (directory-files (file-name-directory file) t nil t) 'string<)))
           (pos (mod (+ (cl-position file files :test 'equal) (if backward -1 1))
                     (length files))))
      (find-file (nth pos files)))))

;;;###autoload
(defun find-previous-file ()
  (interactive)
  (find-next-file 1))

;;; bbatsov

(defun er-auto-create-missing-dirs ()
  (let ((target-dir (file-name-directory buffer-file-name)))
    (unless (file-exists-p target-dir)
      (make-directory target-dir t))))

;;; yrr

(defun save-in-tmp-dir ()
  "Save current buffer in tmp folder"
  (interactive)
  (let* ((bn (buffer-name))
         (fn (concat (file-name-directory "~/tmp/") bn)))
    (write-file fn)))

;;; daanturo

;;;###autoload
(defun daanturo-open-files-with-mode-in-dir (mode dir &rest cmds)
  "In DIR, open all files with the same major-mode as MODE silently.
Run CMDS on them."
  (interactive)
  (save-window-excursion
    (let ((regexp (daanturo-mode-regexp-list mode 'single 'dont-load)))
      ;; Sometimes `directory-files'' MATCH doesn't match correctly
      (dolist (file (directory-files dir))
        (when (and (string-match-p regexp file)
                   (not (get-file-buffer file)))
          (with-current-buffer (find-file-noselect file 'nowarn)
            (mapc #'funcall cmds)))))))

;;;###autoload
(defun daanturo-completing-read-multiple-files (prompt &optional dir default-filename mustmatch initial predicate)
  (dlet ((default-directory (or dir default-directory)))
    (completing-read-multiple
     prompt 'completion-file-name-table
     predicate mustmatch nil 'file-name-history default-filename)))

;;; tramp

;;;###autoload
(defun sd/tramp-remote-find-file-for-me (f)
  "Open F."
  (interactive (list (read-file-name "tramp: "
                                     "/ssh:sdobrau@"
                                     nil ;; "/scp:"
                                     (confirm-nonexistent-file-or-buffer))))
  (find-file f))



(provide 'files-extras)
