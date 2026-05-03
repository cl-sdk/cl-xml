(defsystem #:cl-soap.test
  :description "Tests for cl-soap."
  :license "MIT"
  :depends-on ("cl-xml" "cl-soap" "fiveam")
  :components ((:module "t"
                :components
                ((:file "cl-soap-package")
                 (:file "cl-soap-tests" :depends-on ("cl-soap-package"))))))
