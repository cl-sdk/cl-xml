(defsystem #:cl-wsdl
  :description "WSDL 2.0 support for cl-xml."
  :version "0.1.0"
  :author "Bruno Dias <dias.h.bruno@gmail.com>"
  :maintainer "Bruno Dias <dias.h.bruno@gmail.com>"
  :license "Unlicense"
  :homepage "https://github.com/cl-sdk/cl-xml"
  :source-control (:git "https://github.com/cl-sdk/cl-xml")
  :bug-tracker "https://github.com/cl-sdk/cl-xml/issues"
  :depends-on (#:cl-xml)
  :components ((:file "wsdl-package")
               (:file "wsdl" :depends-on ("wsdl-package"))))
