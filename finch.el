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

;;  This package lets you work with Xcode projects in Emacs.
;;  This isn't a replacement for Xcode by any means, but it should allow you to minimise the time spent in that hellspawn IDE.
;;  Features;
;;      - Find and build a SCHEME within a PROJECT file (.xcodeproj or .xcworkspace file)
;;      - Find and run tests

;; 1. Select A Project
;; 2. Select A Scheme
;; 3. Select A Simulator
;; 4. Build scheme
;; 5. Install app
;; 6. Launch app

;;; Code:

;; code goes here
(require 'dash)
(require 'f)
(require 's)
(require 'json)
(require 'vertico)
;; VARS

;; FILES
(defun -finch-list-project-file (directory)
  "Lists out all Xcode project files in DIRECTORY."
  (interactive)
  (f-entries directory (lambda (file) (or (s-matches? "xcworkspace" file)(s-matches? "xcodeproj" file)))))

(defun finch-select-project ()
  "Sets the 'finch-selected-project' variable from a users selection."
  (interactive)
  (unless (boundp 'finch-selected-project)
    (setq dir (read-string "Enter a directory: ")))
  (setq finch-selected-project (car (completing-read-multiple "Select project: " (-finch-list-project-file dir)))))

;; SCHEMES
(defun finch-list-schemes (project)
  "Lists all schemes found in PROJECT."
  (interactive)
  (message (format "xcodebuild -list -json -%s %s 2>/dev/null"
                   (if
                       (s-matches? "xcworkspace" project)
                       "workspace"
                     "project")
                   project))
  (cdr (assoc 'schemes (assoc 'project
                              (json-read-from-string
                               (shell-command-to-string
                                (format "xcodebuild -list -json -%s %s 2>/dev/null"
                                        (if
                                            (s-matches? "xcworkspace" project)
                                            "workspace"
                                          "project")
                                        project)))))))

(defun finch-select-scheme ()
  "Sets the 'finch-selected-scheme' variable from a users selection."
  (interactive)
  (unless (boundp 'finch-selected-project)
    (finch-select-project))
  (setq finch-selected-scheme (car (completing-read-multiple "Select scheme: " (finch-list-schemes finch-selected-project)))))

;; SIMULATORS
;; This "works" in so much as it returns a list of simulators, but displaying this is going to be a pain.
;; Further work;
;;      - Pass this structure to Vertico and display a buffer of simulators by their name
;;      - When a user selects from the list, that sets the set simulator, which is then used by finch-boot-simulator
(defun -finch-get-simulators ()
  "List simulators."
  (cdr (assoc 'devices
              (json-read-from-string
               (shell-command-to-string
                (format "xcrun simctl list --json devices available"))))))

(defun finch-boot-simulator (uuid)
  "Boot simulator by UUID."
  (interactive)
  (shell-command-to-string
   (format "open -a 'Simulator' --args -CurrentDeviceUDID %s" uuid)))

;; RUNTIMES
(defun -finch-get-runtimes ()
  (interactive)
  (mapcar (lambda (elem)
            (message "%s" (car elem)))
          (-finch-get-simulators)))

(defun finch-select-runtime ()
  "Sets the 'finch-selected-runtime' variable from a users selection."
  (interactive)
  (setq finch-selected-runtime (car (completing-read-multiple "Select runtime: " (-finch-get-runtimes)))))

;; BUILD
(defun finch-build-target (project scheme sdk)
  "Builds a given SCHEME for a PROJECT for SDK."
  (interactive)
  (with-temp-buffer
    (async-shell-command
     (format "xcodebuild -project %s -scheme %s build -sdk %s CONFIGURATION_BUILD_DIR='build'" project scheme sdk))))

;; INSTALL
(defun finch-install (app)
  "Installs APP on booted simulator."
  (interactive)
  (with-temp-buffer
    (shell-command
     (format "xcrun simctl install booted %s" app))))

;; LAUNCH
(defun finch-launch (app)
  "Launches APP on booted simulator."
  (interactive)
  (with-temp-buffer
    (shell-command
     (format "xcrun simctl launch booted %s" app))))
;; xcrun simctl install booted $APP_PATH
;; INTERNAL
;; TODO: Code Signing
;; TODO: SDKs
;;      xcodebuild -showsdks -json
;; UTILS
(defun -print-type (elem)
  (message "Type of my-var: %s" (type-of (symbol-value 'elem))))


(provide 'finch)
;;; finch.el ends here

;; Examples
;; TODO, get the simulators working

(defun finch-get-simulators ()
  (interactive)
  (mapcar (lambda (elem)
            (cdr elem))
          (-finch-get-simulators)))

;; TODO Get the SDKs
;; (defvar finch-sample-sdk "iphonesimulator16.1")
;; ;; Display the simulators
;; (finch-boot-simulator "2DEE1AF4-5BC0-44A7-929C-8A2B4AEEDDD3")
;; ;; Now pass the PROJECT and the SCHEME to the build command
;; (finch-build-target finch-sample-project-file finch-sample-schemes finch-sdk)
;;
;; ;; Run the app
;; (finch-install "SampleProject/build/SampleProject.app")
;; (finch-launch "com.adamf.SampleProject")
