(defsystem #:cl-xsd.test
  :description "Tests for cl-xsd."
  :license "MIT"
  :depends-on ("cl-xml" "cl-xsd" "fiveam")
  :components ((:module "t"
                :components
                ((:file "cl-xsd-package")
                 (:file "cl-xsd-tests" :depends-on ("cl-xsd-package"))))))
