(defsystem #:cl-xml.test
  :description "Tests for cl-xml."
  :license "MIT"
  :depends-on ("cl-xml" "cl-xsd" "cl-soap" "cl-wsdl" "fiveam" "trivial-gray-streams")
  :components ((:module "t"
                :components
                ((:file "package")
                 (:file "cl-xml-tests")))))
