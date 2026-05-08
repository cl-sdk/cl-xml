(defsystem #:cl-soap.test
  :description "Tests for cl-soap."
  :version "0.1.0"
  :author "Bruno Dias <dias.h.bruno@gmail.com>"
  :license "Unlicense"
  :homepage "https://github.com/cl-sdk/cl-xml"
  :source-control (:git "https://github.com/cl-sdk/cl-xml")
  :bug-tracker "https://github.com/cl-sdk/cl-xml/issues"
  :depends-on (#:cl-xml #:cl-soap #:fiveam)
  :components ((:module "t"
                :components
                ((:file "cl-soap-package")
                 (:file "cl-soap-tests" :depends-on ("cl-soap-package"))))))
