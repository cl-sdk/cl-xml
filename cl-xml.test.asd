(defsystem #:cl-xml.test
  :description "Tests for cl-xml."
  :version "0.1.0"
  :author "Bruno Dias <dias.h.bruno@gmail.com>"
  :license "Unlicense"
  :homepage "https://github.com/cl-sdk/cl-xml"
  :source-control (:git "https://github.com/cl-sdk/cl-xml")
  :bug-tracker "https://github.com/cl-sdk/cl-xml/issues"
  :depends-on (#:cl-xml #:fiveam #:trivial-gray-streams)
  :components ((:module "t"
                :components
                ((:file "package")
                 (:file "cl-xml-tests")))))
