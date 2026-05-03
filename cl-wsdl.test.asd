(defsystem #:cl-wsdl.test
  :description "Tests for cl-wsdl."
  :license "MIT"
  :depends-on ("cl-xml" "cl-wsdl" "fiveam")
  :components ((:module "t"
                :components
                ((:file "cl-wsdl-package")
                 (:file "cl-wsdl-tests" :depends-on ("cl-wsdl-package"))))))
