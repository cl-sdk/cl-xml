(defsystem #:cl-xsd.test
  :description "Tests for cl-xsd."
  :version "0.1.0"
  :author "Bruno Dias <dias.h.bruno@gmail.com>"
  :license "Unlicense"
  :homepage "https://github.com/cl-sdk/cl-xml"
  :source-control (:git "https://github.com/cl-sdk/cl-xml")
  :bug-tracker "https://github.com/cl-sdk/cl-xml/issues"
  :depends-on (#:cl-xml #:cl-xsd #:fiveam)
  :components ((:module "t"
                :components
                ((:file "cl-xsd-package")
                 (:file "cl-xsd-tests" :depends-on ("cl-xsd-package"))))))
