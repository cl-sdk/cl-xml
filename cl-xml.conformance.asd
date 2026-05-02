(defsystem "cl-xml.conformance"
  :description "W3C XML Conformance Test Suite runner for cl-xml."
  :license "MIT"
  :depends-on ("cl-xml" "uiop")
  :components ((:module "t"
                :components
                ((:file "w3c-conformance")))))
