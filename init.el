;;; Aniruddh Agarwal's Emacs config

;;; The systems I use this on run macOS and Windows. I frequently SSH
;;; onto Linux servers and primarily edit C++ and Python. I write
;;; Lean, Haskell and Rust whenever I can. This configuration is
;;; optimized around that. I've tried to keep it fairly minimal.

;; Who am I? That's a deep question...thankfully Emacs expects a simple
;; enough answer.
(setq user-full-name "Aniruddh Agarwal"
      user-mail-address "me@anrddh.me")

;; Some configuration is global, some depends on the OS and some
;; depends on the hostname. This preliminary section sets up utilities
;; that make this easily possibly.
(setq ani-is-macos (eq system-type 'darwin))
(defmacro ani-macos-only (&rest r) `(when ani-is-macos ,@r))

(setq ani-is-linux (eq system-type 'gnu/linux))
(defmacro ani-linux-only (&rest r) `(when ani-is-linux ,@r))

(setq ani-is-windows (eq system-type 'windows-nt))
(defmacro ani-windows-only (&rest r) `(when ani-is-windows ,@r))

; My primary machine
(setq ani-is-main (eq (system-name) "ani-primary-mac.local"))
(defmacro ani-main-only (&rest r) `(when ani-is-main ,@r))

;; If I'm using a Windows machine, I'm doing work-related stuff
(ani-windows-only
 (setq user-mail-address "aniruddh.agarwal@squarepoint-capital.com"))

;;; My workflow is heavily dependent on TRAMP.

;; Use plink for TRAMP on Windows, and
(setq ani-tramp-connection-method (if ani-is-windows "/plink:" "/ssh:"))

(defun ani-connect-tramp (user host port &optional dir)
  "Connect via TRAMP to the specified SSH server."
  (or dir (setq dir "~")) ;; Visit home by default
  (dired (concat ani-tramp-connection-method user "@" host "#" port ":" dir)))

(defun ani-connect-ubuntu ()
  (interactive)
  (ani-connect-tramp "ani" "localhost" "2200"))

(defun ani-connect-work-dev ()
  (interactive)
  (ani-connect-tramp "agarwaan" (read-string "Hostname:") "22"))

(ani-main-only
 (setq org-directory "~/Dropbox/org")
 (setq organizer-file (concat org-directory "/organizer.org")))

;; Display line and column numbers in modeline
(column-number-mode)
(size-indication-mode)

;; UTF-8 by default
(prefer-coding-system 'utf-8)

;; Get rid of the startup splash screen
(setq inhibit-startup-message t
      initial-scratch-message "")

;; Disable gc when starting up
(setq gc-cons-threshold 64000000)
(add-hook 'after-init-hook #'(lambda ()
                               ;; restore after startup
                               (setq gc-cons-threshold 800000)))

;; Backup-file stuff
(setq backup-by-copying              t
      backup-directory-alist         '((".*" . "~/.emacs-saves/"))
      auto-save-file-name-transforms '((".*" "~/.emacs-saves/" t))
      delete-old-versions            t
      kept-new-versions              6
      kept-old-versions              2
      version-control                t
      load-prefer-newer              t)

;; de-uglify the UI
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tooltip-mode -1)
(fringe-mode -1)
(set-face-attribute 'region nil :background "#87ceeb")

;; Set default font size to 19pt
(set-face-attribute 'default nil :height 190)

(ani-macos-only
 (setq mac-option-modifier 'super   ;; Map <Opt> to Super
       mac-command-modifier 'meta)) ;; Map <Cmd> to Meta

;; Auto reload files from disk
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; Remove trailing spaces
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;;;
;;; PACKAGES
;;;

;; Macaulay 2 start
(ani-main-only
 (setq ani-m2-dir "/Applications/Macaulay2-1.15/")

 ;; add "/Applications/Macaulay2-1.15/share/emacs/site-lisp" to
 ;; load-path if it isn't there
 (setq ani-m2-lisp (concat ani-m2-dir "share/emacs/site-lisp"))
 (if (not (member ani-m2-lisp load-path))
     (setq load-path (cons ani-m2-lisp load-path)))

 ;; add "/Applications/Macaulay2-1.15/share/info" to
 ;; Info-default-directory-list if it isn't there
 (setq ani-m2-info (concat ani-m2-dir "share/info"))
 (if (not (member ani-m2-info Info-default-directory-list))
     (setq Info-default-directory-list
           (cons ani-m2-info Info-default-directory-list)))

 (load "M2-init"))
;; Macaulay 2 end

(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(package-initialize)

(setq use-package-always-ensure t)
(setq use-package-compute-statistics t)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(use-package diminish)

(use-package helpful
  :bind
  ("C-h f"   . 'helpful-callable)
  ("C-h v"   . 'helpful-variable)
  ("C-h k"   . 'helpful-key)
  ("C-c C-d" . 'helpful-at-point)
  ("C-h F"   . 'helpful-function)
  ("C-h C"   . 'helpful-command)
  :init
  (setq counsel-describe-function-function #'helpful-callable
        counsel-describe-variable-function #'helpful-variable))

(use-package undo-tree
  :diminish
  :bind ("C-x u" . 'undo-tree-visualize)
  :config
  (global-undo-tree-mode 1))

(use-package evil
  :init
  (setq evil-want-C-u-scroll  t
        evil-want-integration t
        evil-want-keybinding nil)
  :bind ("C-e" . move-end-of-line)
  :config
  (use-package evil-collection
    :after evil
    :config
    (evil-collection-init))

  (use-package evil-escape
    :diminish
    :after evil
    :init
    (setq evil-escape-key-sequence "jk")
    :config
    (evil-escape-mode))

  (use-package evil-surround
    :after evil
    :config
    (global-evil-surround-mode)))

(evil-mode 1)

(use-package exec-path-from-shell
  :if ani-is-macos
  :config
  (exec-path-from-shell-initialize))

(use-package which-key
  :diminish
  :config (which-key-mode))

(use-package ivy
  :diminish
  :init (ivy-mode 1))

(use-package counsel)

(use-package swiper
  :bind
  ("C-s"     . counsel-grep-or-swiper)
  ("C-c C-r" . ivy-resume)
  ("M-x"     . counsel-M-x)
  ("C-x C-f" . counsel-find-file)
  ("C-c k"   . counsel-rg)
  ("C-c i"   . counsel-imenu)
  :init
  (setq ivy-use-selectable-prompt t)
  (setq counsel-grep-base-command
        "rg -i -M 120 --no-heading --line-number --color never '%s' %s"
        ivy-use-virtual-buffers t)
  :config
  (define-key read-expression-map (kbd "C-r") 'counsel-expression-history))

(use-package org
  :ensure nil
  :bind
  ("C-c a" . org-agenda)
  ("C-c c" . org-capture)
  :custom
  (org-log-done 'time "Log timestamp when marking a task as DONE")
  (org-agenda-files (list "~/Dropbox/org/"))
  :config
  (add-to-list 'org-modules 'org-habits))

(ani-main-only
 (setq ani-bibtex-bibliography '("~/Dropbox/bib/books.bib"
                                 "~/Dropbox/bib/papers.bib"
                                 "~/Dropbox/bib/web.bib"
                                 "/usr/local/texlive/2019/texmf-dist/bibtex/bib/beebe/tugboat.bib"))
      ani-bibtex-pdfs '("~/Dropbox/bib/"))

(use-package org-ref
  :if ani-is-main
  :init
  (setq org-ref-default-bibliography ani-bibtex-bibliography)
  (setq org-ref-pdf-directory "~/Dropbox/bib/"))

(use-package org-board
  :if ani-is-main
  :init
  (setq org-board-default-browser 'system) ;; don't open links in eww
  :config
  (global-set-key (kbd "C-c o") org-board-keymap))

(use-package ivy-bibtex
  :if ani-is-main
  :bind ("C-c b" . ivy-bibtex)
  :config
  (setq bibtex-completion-display-formats '((t . "${author:36} ${title:*} ${year:4} ${=has-pdf=:1} ${=type=:7}"))
        ivy-re-builders-alist '((ivy-bibtex . ivy--regex-ignore-order)
                                (t . ivy--regex-plus))
        bibtex-completion-bibliography ani-bibtex-bibliography
        bibtex-completion-library-path ani-bibtex-pdfs
        bibtex-completion-pdf-extension '(".pdf" ".ps" ".djvu")
        bibtex-completion-additional-search-fields '(tags)))

(use-package auctex-latexmk
  :after tex
  :if ani-is-main
  :init
  (setq auctex-latexmk-inherit-TeX-PDF-mode t)
  :config
  (auctex-latexmk-setup))

(use-package tex
  :defer t
  :ensure auctex
  :hook
  (LaTeX-mode . flyspell-mode)
  :init
  (setq TeX-PDF-mode t
        TeX-auto-save t
        TeX-parse-self t
        LaTeX-biblatex-use-Biber t
        TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view))
        TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-source-correlate-method 'synctex
        TeX-source-correlate-start-server t)
  :config
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer))

(use-package reftex
  :ensure nil
  :hook (LaTeX-mode . turn-on-reftex)
  :init
  (setq reftex-plug-into-AUCTeX t
        reftex-default-bibliography ani-bibtex-bibliography))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package avy
  :bind
  ("C-:"   . 'avy-goto-char)
  ("C-'"   . 'avy-goto-char-timer)
  ("M-g f" . 'avy-goto-line))

;;; 80-char rule
(use-package whitespace
  :ensure nil
  :diminish
  :init
  (setq whitespace-line-column 80  ;; limit line length
        whitespace-style '(face lines-tail))
  :config
  (add-hook 'prog-mode-hook 'whitespace-mode))

(use-package company
  :hook (after-init . global-company-mode)
  :bind ("M-/" . 'company-complete-common-or-cycle)
  :diminish
  :config
  (setq company-idle-delay 0
        company-minimum-prefix-length 1))

(use-package flycheck
  :hook (prog-mode . flycheck-mode)
  :init
  (setq flycheck-clang-language-standard "c++17"
        flycheck-gcc-language-standard "c++17"
        flycheck-check-syntax-automatically '(mode-enabled idle-change save)
        flycheck-checker-error-threshold 1000))

(use-package dired
  :ensure nil
  :init
  (ani-macos-only
   (setq dired-use-ls-dired t
         insert-directory-program "/Users/anrddh/.nix-profile/bin/ls"))
  :custom
  (dired-listing-switches "-aBhl --group-directories-first"))

(use-package ivy-dired-history
  :init
  (require 'savehist)
  (add-to-list 'savehist-additional-variables 'ivy-dired-history-variable)
  (savehist-mode 1)
  (with-eval-after-load 'dired
    (require 'ivy-dired-history)
    (define-key dired-mode-map "," 'dired)))

(use-package flyspell
  :if ani-is-main
  :ensure nil
  :diminish
  :hook (text-mode . flyspell-mode)
  :hook (prog-mode . flyspell-prog-mode)
  :init
  (when (executable-find "hunspell")
    (setq-default ispell-program-name "hunspell")
    (setq ispell-really-hunspell t)
    (setq ispell-dictionary "en_US")))

(use-package hungry-delete
  :diminish
  :config
  (global-hungry-delete-mode))

;; git setup

(use-package magit
  :bind ("C-x g" . magit-status))

(use-package evil-magit
  :after magit
  :init (setq evil-magit-state 'normal))

(cl-defun ani-magit-check-file-and-popup (&optional (file (buffer-file-name)))
  (require 'magit)
  (when (and file (magit-anything-modified-p t file))
    (message "This file has uncommited changes.")))

(add-hook 'find-file-hook 'ani-magit-check-file-and-popup)

(use-package fish-mode)

(use-package unicode-fonts
  :config
 (unicode-fonts-setup))

(use-package uniquify
  :ensure nil
  :custom
  (uniquify-separator "/")
  (uniquify-buffer-name-style 'forward))

(use-package direnv
  :diminish
  :config
  (direnv-mode))

(use-package proof-general)
(use-package lean-mode)
(use-package json-mode)
(use-package nix-mode)

(use-package pdf-tools
  :if ani-is-main
  :init
  (setq pdf-view-use-imagemagick t)
  (setq pdf-view-use-scaling t)
  (pdf-loader-install))

(use-package server
  :ensure t
  :init
  (server-mode 1)
  :config
  (unless (server-running-p)
    (server-start)))

(use-package lsp-mode
  :hook ((lsp-mode  . lsp-enable-which-key-integration)
         (rust-mode . lsp))
  :init
  (setq lsp-rust-server 'rust-analyzer))

(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)

(use-package doom-themes
  :config
  (load-theme 'doom-acario-light))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(custom-safe-themes
   '("9b01a258b57067426cc3c8155330b0381ae0d8dd41d5345b5eddac69f40d409b" "1d50bd38eed63d8de5fcfce37c4bb2f660a02d3dff9cbfd807a309db671ff1af" "93ed23c504b202cf96ee591138b0012c295338f38046a1f3c14522d4a64d7308" "99ea831ca79a916f1bd789de366b639d09811501e8c092c85b2cb7d697777f93" default))
 '(dired-listing-switches "-aBhl --group-directories-first")
 '(org-agenda-files '("~/Dropbox/org/"))
 '(org-log-done 'time)
 '(package-selected-packages
   '(fish-mode yasnippet cargo lean-mode doom-themes json-mode nix-mode proof-general direnv unicode-fonts evil-surround evil-escape evil-collection evil-magit magit hungry-delete ivy-dired-history flycheck avy rainbow-delimiters auctex-latexmk ivy-bibtex org-board org-ref counsel ivy which-key exec-path-from-shell evil undo-tree helpful diminish use-package))
 '(size-indication-mode t)
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style 'forward nil (uniquify) "Customized with use-package uniquify")
 '(uniquify-separator "/"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-comment-face ((t (:foreground "#a5a4a5" :slant italic :family "Hack")))))
