(defsystem #:cl-xml.test
  :description "Tests for cl-xml."
  :license "MIT"
  :depends-on ("cl-xml" "fiveam")
  :components ((:module "t"
                :components
                ((:file "package")
                 (:file "cl-xml-tests")))))
