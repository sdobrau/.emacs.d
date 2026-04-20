;; -*- lexical-binding: t -*-

(leaf
  engine-mode
  :quelpa t
  :require t
  :custom
  ((engine/keybinding-prefix . "M-s s")
    (engine/browser-function . 'eww-browse-url))
  :config
  (defengine google "https://www.google.com/search?q=%s" :keybinding "s")
  (defengine
    duckduckgo
    "https://html.duckduckgo.com/html?q=%s"
    :keybinding "d"))

(leaf
  counsel-chrome-bm
  :bind ("C-x r ." . counsel-chrome-bm)
  :custom
  (
    (counsel-chrome-bm-file
      .
      "/home/sdobrau/.config/chromium/Default/Bookmarks")
    (counsel-chrome-bm-default-action . #'counsel-chrome-bm--open-in-eww)))

(leaf ace-link :ensure t)

(leaf
  rmail-ordered-headers
  :quelpa (rmail-ordered-headers :fetcher github :repo "ir33k/rmail-ordered-headers")
  :require t)
