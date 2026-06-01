;; -*- lexical-binding: t -*-

;; https://lists.gnu.org/archive/html/bug-gnu-emacs/2023-03/msg00725.html

;;;###autoload
(defun sd/kill-all-eww ()
  (mapcar (lambda (buf) (if (eq (buffer-local-value 'major-mode buf) #'eww-mode)
        (kill-buffer buf))) (buffer-list)))

;;;###autoload
(defun sd/h2o-current-eww-url (&optional args)
  (interactive "P")
  (when-let* ((url (plist-get eww-data :url))
             (title (plist-get eww-data :title)))
    (async-shell-command
     (format "source ${HOME}/bin/crawl-sitemap/crawl-sitemap.sh && export -f h2o && pushd ${HOME}/org/stash/ && h2o %s" url) nil nil)
    (if current-prefix-arg (find-file (format "${HOME}/org/stash/%s.org" title)))))



(provide 'eww-extras)
