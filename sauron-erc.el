;;; sauron-erc -- tracking your ERC irc-channels
;;
;; Copyright (C) 2011 Dirk-Jan C. Binnema

;; Author: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Maintainer: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Keywords: 
;; Version: 0.0

;; This file is not part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:
(require 'erc nil 'noerror)
(eval-when-compile (require 'cl))

(defvar sauron-erc-interesting-events
  '(privmsg current-nick keyword)
  "The list of ERC events we are interested in. Available are:
- privmsg:       a PRIVMSG message received
- join           a JOIN message received
- quit           a QUIT message received
The following events are erc-track
- current-nick:  current nick mentioned in ERC
- keyword:       some keyword mentioned in ERC.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar sr-erc-running nil
  "*internal* Whether sauron erc is running.")

(defun sauron-erc-start ()
  "Start watching ERC."
  (if (not (boundp 'erc-version-string))
    (message "sauron-erc not available")
    (unless sr-erc-running
      (add-hook 'erc-server-PRIVMSG-functions 'sr-erc-PRIVMSG-hook-func)
      (add-hook 'erc-server-JOIN-functions 'sr-erc-JOIN-hook-func)
      (add-hook 'erc-server-PART-functions 'sr-erc-PART-hook-func)
      (add-hook 'erc-server-QUIT-functions 'sr-erc-QUIT-hook-func)
      (setq sr-erc-running t))))

(defun sauron-erc-stop ()
  "Stop watching ERC."
  (when sr-erc-running
    (remove-hook 'erc-server-PRIVMSG-functions 'sr-erc-PRIVMSG-hook-func)
    (remove-hook 'erc-server-JOIN-functions 'sr-erc-JOIN-hook-func)
    (remove-hook 'erc-server-PART-functions 'sr-erc-PART-hook-func)
    (remove-hook 'erc-server-QUIT-functions 'sr-erc-QUIT-hook-func)    
    (setq sr-erc-running nil)))


(defun sr-erc-hook-func (proc parsed event)
  "Hook function, to be called for erc-matched-hook."
  (let* ( (me     (erc-current-nick))
	  (sender (car (erc-parse-user (erc-response.sender parsed))))
	  (target (car (erc-response.command-args parsed)))
	  (msg (erc-response.contents parsed)))
    (sauron-add-event
      'erc
      3
      (concat (propertize sender 'face 'sauron-highlight1-face) " has " 
	(case event
	  ('quit "quited")
	  ('part "parted")
	  ('join "joined")))
      ;; FIXME: assumes we open separate window
      (when (eq event 'joined)
	(lexical-let ((target target)) 
	  (lambda()  (sauron-switch-to-buffer target))))
      `(:event   ,event
	 :sender ,sender
	 :me     ,me
	 :target ,target
	 :msg    ,msg))))


(defun sr-erc-JOIN-hook-func (proc parsed)
  "JOIN hook function."
  (message "JOIN")
  (sr-erc-hook-func proc parse 'join))

(defun sr-erc-QUIT-hook-func (proc parsed)
  "QUIT hook function."
  (message "QUIT")
  (sr-erc-hook-func proc parse 'quit))

(defun sr-erc-PART-hook-func (proc parsed)
  "PART hook function."
    (message "PART")
  (sr-erc-hook-func proc parse 'part))


(defun sr-erc-PRIVMSG-hook-func (proc parsed)
  "Hook function, to be called for erc-matched-hook."
  (let* ( (me     (erc-current-nick))
	  (sender (car (erc-parse-user (erc-response.sender parsed))))
	  (target (car (erc-response.command-args parsed)))
	  (msg (erc-response.contents parsed))
	  (prio
	    (cond
	      ((string= sender "root") 2)    ;; bitlbee stuff
	      ((string= me target)     4)    ;; private message for me => prio 4
	      ((string-match me msg)   3)    ;; I'm mentioned => prio 3 (FIXME)
	      (t                       2)))) ;; default 
    (sauron-add-event
      'erc
      prio
      (concat
	(propertize sender 'face 'sauron-highlight1-face) "→"
	(propertize target 'face 'sauron-highlight2-face) " "
	msg)
      ;; FIXME: assumes we open separate window
      (lexical-let ((target target) (me me)) 
	(lambda()  (sauron-switch-to-buffer
		     (if (string= target me) sender target))))
      `(:event   privmsg
	 :sender ,sender
	 :me     ,me
	 :target ,target
	 :msg    ,msg))))
 
(provide 'sauron-erc)


