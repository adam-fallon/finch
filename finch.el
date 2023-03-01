;;; finch.el --- Work with xcode projects

;; Author: Adam Fallon
;; Keywords: lisp xcode
;; Homepage: https://adamfallon.com
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;  This package lets you work with Xcode projects in emacs.
;;  This isn't a replacement for Xcode by any means, but it should allow you to minimise the time spent in that hellspawn IDE.
;;  Features;
;;      - Find and build a SCHEME within a PROJECT file (.xcodeproj or .xcworkspace file)
;;      - Find and run tests

;;; Code:

;; code goes here
(require 'dash)
(require 'f)
(require 's)
(require 'json)
;; VARS

;; FILES
(defun finch-list-project-file (directory)
  "Lists out all Xcode project files in DIRECTORY."
  (interactive)
  (f-entries directory (lambda (file) (or (s-matches? "xcodeproj" file)))))

;; SCHEMES
(defun finch-list-schemes (project)
  "Lists all schemes found in PROJECT"
  (interactive)
  (cdr (assoc 'schemes (assoc 'project
                              (json-read-from-string
                               (shell-command-to-string
                                (format "xcodebuild -list -json -project %s 2>/dev/null" project)))))))

;; SIMULATORS
(defun finch-get-simulators ()
  "List simulators."
  (interactive)
  (cdr (assoc 'devices
              (json-read-from-string
               (shell-command-to-string
                (format "xcrun simctl list --json devices available"))))))

;; BUILD
(defun finch-build-target (project scheme)
  "Builds a given SCHEME."
  (interactive)
  (with-temp-buffer
    (shell-command
     (format "xcodebuild -project %s -scheme %s" project scheme))))

;; INTERNAL


(provide 'finch)
;;; finch.el ends here

;; Examples
(defvar finch-sample-project-file (finch-list-project-file "~/Desktop/SampleProject"))
;; Get the schemes
(defvar finch-sample-schemes (finch-list-schemes (car finch-sample-project-file)))
;; Get the simulators, again only selecting the top of the list
;; TODO, get the simulators working
;;
;; Now pass the PROJECT and the SCHEME to the build command
(finch-build-target finch-sample-project-file finch-sample-schemes)
