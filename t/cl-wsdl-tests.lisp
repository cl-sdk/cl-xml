(in-package #:cl-wsdl.test)

(def-suite cl-wsdl-suite
  :description "Test suite for cl-wsdl.")

(in-suite cl-wsdl-suite)

;;; ── WSDL ─────────────────────────────────────────────────────────────────

;;; A minimal but complete WSDL 2.0 document used by many tests below.
(defparameter +simple-wsdl+
  "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/hello\">
  <wsdl:interface name=\"HelloInterface\">
    <wsdl:operation name=\"sayHello\"
                    pattern=\"http://www.w3.org/ns/wsdl/in-out\">
      <wsdl:input  element=\"tns:SayHelloRequest\" />
      <wsdl:output element=\"tns:SayHelloResponse\" />
    </wsdl:operation>
  </wsdl:interface>
  <wsdl:binding name=\"HelloBinding\"
                interface=\"tns:HelloInterface\"
                type=\"http://www.w3.org/ns/wsdl/soap\">
    <wsdl:operation ref=\"tns:sayHello\" />
  </wsdl:binding>
  <wsdl:service name=\"HelloService\"
                interface=\"tns:HelloInterface\">
    <wsdl:endpoint name=\"HelloEndpoint\"
                   binding=\"tns:HelloBinding\"
                   address=\"http://example.com/hello\" />
  </wsdl:service>
</wsdl:description>")

(test wsdl-namespace-constant
  "The WSDL 2.0 namespace URI constant has the correct value."
  (is (string= "http://www.w3.org/ns/wsdl"
               cl-wsdl:+wsdl-2.0-namespace+)))

(test parse-wsdl-returns-description
  "parse-wsdl returns a wsdl-description struct."
  (let ((desc (cl-wsdl:parse-wsdl +simple-wsdl+)))
    (is (cl-wsdl:wsdl-description-p desc))))

(test parse-wsdl-target-namespace
  "parse-wsdl captures the targetNamespace attribute."
  (let ((desc (cl-wsdl:parse-wsdl +simple-wsdl+)))
    (is (string= "http://example.com/hello"
                 (cl-wsdl:wsdl-description-target-namespace desc)))))

(test parse-wsdl-interface-count
  "parse-wsdl populates the interfaces list."
  (let ((desc (cl-wsdl:parse-wsdl +simple-wsdl+)))
    (is (= 1 (length (cl-wsdl:wsdl-description-interfaces desc))))))

(test parse-wsdl-interface-name
  "parse-wsdl captures the interface name."
  (let* ((desc  (cl-wsdl:parse-wsdl +simple-wsdl+))
         (iface (first (cl-wsdl:wsdl-description-interfaces desc))))
    (is (cl-wsdl:wsdl-interface-p iface))
    (is (string= "HelloInterface" (cl-wsdl:wsdl-interface-name iface)))))

(test parse-wsdl-interface-operation
  "parse-wsdl parses wsdl:operation inside wsdl:interface."
  (let* ((desc  (cl-wsdl:parse-wsdl +simple-wsdl+))
         (iface (first (cl-wsdl:wsdl-description-interfaces desc)))
         (op    (first (cl-wsdl:wsdl-interface-operations iface))))
    (is (cl-wsdl:wsdl-interface-operation-p op))
    (is (string= "sayHello" (cl-wsdl:wsdl-interface-operation-name op)))
    (is (string= "http://www.w3.org/ns/wsdl/in-out"
                 (cl-wsdl:wsdl-interface-operation-pattern op)))))

(test parse-wsdl-operation-input-output
  "parse-wsdl records wsdl:input and wsdl:output as wsdl-message-ref structs."
  (let* ((desc  (cl-wsdl:parse-wsdl +simple-wsdl+))
         (op    (first (cl-wsdl:wsdl-interface-operations
                        (first (cl-wsdl:wsdl-description-interfaces desc)))))
         (in    (first (cl-wsdl:wsdl-interface-operation-inputs op)))
         (out   (first (cl-wsdl:wsdl-interface-operation-outputs op))))
    (is (cl-wsdl:wsdl-message-ref-p in))
    (is (string= "tns:SayHelloRequest" (cl-wsdl:wsdl-message-ref-element in)))
    (is (cl-wsdl:wsdl-message-ref-p out))
    (is (string= "tns:SayHelloResponse" (cl-wsdl:wsdl-message-ref-element out)))))

(test parse-wsdl-binding
  "parse-wsdl parses wsdl:binding with name, interface, and type."
  (let* ((desc    (cl-wsdl:parse-wsdl +simple-wsdl+))
         (binding (first (cl-wsdl:wsdl-description-bindings desc))))
    (is (cl-wsdl:wsdl-binding-p binding))
    (is (string= "HelloBinding"  (cl-wsdl:wsdl-binding-name binding)))
    (is (string= "tns:HelloInterface" (cl-wsdl:wsdl-binding-interface binding)))
    (is (string= "http://www.w3.org/ns/wsdl/soap"
                 (cl-wsdl:wsdl-binding-type binding)))))

(test parse-wsdl-binding-operation
  "parse-wsdl parses wsdl:operation inside wsdl:binding."
  (let* ((desc    (cl-wsdl:parse-wsdl +simple-wsdl+))
         (binding (first (cl-wsdl:wsdl-description-bindings desc)))
         (bop     (first (cl-wsdl:wsdl-binding-operations binding))))
    (is (cl-wsdl:wsdl-binding-operation-p bop))
    (is (string= "tns:sayHello" (cl-wsdl:wsdl-binding-operation-ref bop)))))

(test parse-wsdl-service
  "parse-wsdl parses wsdl:service."
  (let* ((desc    (cl-wsdl:parse-wsdl +simple-wsdl+))
         (service (first (cl-wsdl:wsdl-description-services desc))))
    (is (cl-wsdl:wsdl-service-p service))
    (is (string= "HelloService"      (cl-wsdl:wsdl-service-name service)))
    (is (string= "tns:HelloInterface" (cl-wsdl:wsdl-service-interface service)))))

(test parse-wsdl-endpoint
  "parse-wsdl parses wsdl:endpoint inside wsdl:service."
  (let* ((desc    (cl-wsdl:parse-wsdl +simple-wsdl+))
         (service (first (cl-wsdl:wsdl-description-services desc)))
         (ep      (first (cl-wsdl:wsdl-service-endpoints service))))
    (is (cl-wsdl:wsdl-endpoint-p ep))
    (is (string= "HelloEndpoint"    (cl-wsdl:wsdl-endpoint-name ep)))
    (is (string= "tns:HelloBinding" (cl-wsdl:wsdl-endpoint-binding ep)))
    (is (string= "http://example.com/hello" (cl-wsdl:wsdl-endpoint-address ep)))))

(test parse-wsdl-interface-fault
  "parse-wsdl parses wsdl:fault inside wsdl:interface."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:interface name=\"FaultIface\">
    <wsdl:fault name=\"NotFound\" element=\"tns:NotFoundFault\" />
  </wsdl:interface>
</wsdl:description>"))
         (iface (first (cl-wsdl:wsdl-description-interfaces desc)))
         (fault (first (cl-wsdl:wsdl-interface-faults iface))))
    (is (cl-wsdl:wsdl-interface-fault-p fault))
    (is (string= "NotFound" (cl-wsdl:wsdl-interface-fault-name fault)))
    (is (string= "tns:NotFoundFault" (cl-wsdl:wsdl-interface-fault-element fault)))))

(test parse-wsdl-infault-outfault
  "parse-wsdl parses wsdl:infault and wsdl:outfault inside wsdl:operation."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:interface name=\"FaultOp\">
    <wsdl:operation name=\"op1\"
                    pattern=\"http://www.w3.org/ns/wsdl/in-out\">
      <wsdl:input  element=\"tns:Req\" />
      <wsdl:output element=\"tns:Resp\" />
      <wsdl:infault  ref=\"tns:InputFault\" />
      <wsdl:outfault ref=\"tns:OutputFault\" />
    </wsdl:operation>
  </wsdl:interface>
</wsdl:description>"))
         (op (first (cl-wsdl:wsdl-interface-operations
                     (first (cl-wsdl:wsdl-description-interfaces desc))))))
    (let ((inf  (first (cl-wsdl:wsdl-interface-operation-in-faults op)))
          (outf (first (cl-wsdl:wsdl-interface-operation-out-faults op))))
      (is (cl-wsdl:wsdl-fault-ref-p inf))
      (is (string= "tns:InputFault"  (cl-wsdl:wsdl-fault-ref-ref inf)))
      (is (cl-wsdl:wsdl-fault-ref-p outf))
      (is (string= "tns:OutputFault" (cl-wsdl:wsdl-fault-ref-ref outf))))))

(test parse-wsdl-interface-extends
  "parse-wsdl captures the extends attribute as a list of names."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:interface name=\"Child\" extends=\"tns:Base1 tns:Base2\" />
</wsdl:description>"))
         (iface (first (cl-wsdl:wsdl-description-interfaces desc))))
    (is (equal '("tns:Base1" "tns:Base2")
               (cl-wsdl:wsdl-interface-extends iface)))))

(test parse-wsdl-import
  "parse-wsdl captures wsdl:import elements."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:import namespace=\"http://other.example.com/\"
               location=\"other.wsdl\" />
</wsdl:description>"))
         (imp (first (cl-wsdl:wsdl-description-imports desc))))
    (is (cl-wsdl:wsdl-import-p imp))
    (is (string= "http://other.example.com/" (cl-wsdl:wsdl-import-namespace imp)))
    (is (string= "other.wsdl" (cl-wsdl:wsdl-import-location imp)))))

(test parse-wsdl-include
  "parse-wsdl captures wsdl:include elements."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:include location=\"common.wsdl\" />
</wsdl:description>"))
         (inc (first (cl-wsdl:wsdl-description-includes desc))))
    (is (cl-wsdl:wsdl-include-p inc))
    (is (string= "common.wsdl" (cl-wsdl:wsdl-include-location inc)))))

(test parse-wsdl-types-preserved
  "parse-wsdl stores type children as xml-nodes."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:types>
    <xs:schema targetNamespace=\"http://example.com/\">
      <xs:element name=\"Foo\" type=\"xs:string\" />
    </xs:schema>
  </wsdl:types>
</wsdl:description>")))
    (is (= 1 (length (cl-wsdl:wsdl-description-types desc))))
    (is (cl-xml:xml-node-p (first (cl-wsdl:wsdl-description-types desc))))))

(test parse-wsdl-binding-fault
  "parse-wsdl parses wsdl:fault inside wsdl:binding."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:binding name=\"B\" interface=\"tns:I\"
                type=\"http://www.w3.org/ns/wsdl/soap\">
    <wsdl:fault ref=\"tns:NotFound\" code=\"soap:Sender\" />
  </wsdl:binding>
</wsdl:description>"))
         (bf (first (cl-wsdl:wsdl-binding-faults
                     (first (cl-wsdl:wsdl-description-bindings desc))))))
    (is (cl-wsdl:wsdl-binding-fault-p bf))
    (is (string= "tns:NotFound" (cl-wsdl:wsdl-binding-fault-ref bf)))
    (is (string= "soap:Sender"  (cl-wsdl:wsdl-binding-fault-code bf)))))

(test parse-wsdl-wrong-root-signals-error
  "parse-wsdl signals wsdl-error when the root element is not wsdl:description."
  (signals cl-wsdl:wsdl-error
    (cl-wsdl:parse-wsdl
     "<?xml version=\"1.0\"?>
<wsdl:definitions xmlns:wsdl=\"http://www.w3.org/ns/wsdl\" />")))

(test parse-wsdl-wrong-namespace-signals-error
  "parse-wsdl signals wsdl-error when the namespace URI is not WSDL 2.0."
  (signals cl-wsdl:wsdl-error
    (cl-wsdl:parse-wsdl
     "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://schemas.xmlsoap.org/wsdl/\" />")))

(test serialize-wsdl-returns-string
  "serialize-wsdl with no :stream argument returns a string."
  (let* ((desc (cl-wsdl:parse-wsdl +simple-wsdl+))
         (out  (cl-wsdl:serialize-wsdl desc)))
    (is (stringp out))))

(test serialize-wsdl-contains-declaration
  "serialize-wsdl output starts with an XML declaration."
  (let* ((desc (cl-wsdl:parse-wsdl +simple-wsdl+))
         (out  (cl-wsdl:serialize-wsdl desc)))
    (is (search "<?xml" out))))

(test serialize-wsdl-contains-wsdl-namespace
  "serialize-wsdl output declares the WSDL 2.0 namespace."
  (let* ((desc (cl-wsdl:parse-wsdl +simple-wsdl+))
         (out  (cl-wsdl:serialize-wsdl desc)))
    (is (search "http://www.w3.org/ns/wsdl" out))))

(test serialize-wsdl-to-stream
  "serialize-wsdl writes to a supplied output stream and returns NIL."
  (let* ((desc (cl-wsdl:parse-wsdl +simple-wsdl+))
         (ret  nil))
    (with-output-to-string (s)
      (setf ret (cl-wsdl:serialize-wsdl desc :stream s)))
    (is (null ret))))

(test serialize-wsdl-roundtrip-interface
  "serialize-wsdl output can be re-parsed to recover interface data."
  (let* ((desc1 (cl-wsdl:parse-wsdl +simple-wsdl+))
         (xml   (cl-wsdl:serialize-wsdl desc1))
         (desc2 (cl-wsdl:parse-wsdl xml)))
    (is (= (length (cl-wsdl:wsdl-description-interfaces desc1))
           (length (cl-wsdl:wsdl-description-interfaces desc2))))
    (is (string= (cl-wsdl:wsdl-interface-name
                  (first (cl-wsdl:wsdl-description-interfaces desc1)))
                 (cl-wsdl:wsdl-interface-name
                  (first (cl-wsdl:wsdl-description-interfaces desc2)))))))

(test serialize-wsdl-roundtrip-binding
  "serialize-wsdl output can be re-parsed to recover binding data."
  (let* ((desc1 (cl-wsdl:parse-wsdl +simple-wsdl+))
         (xml   (cl-wsdl:serialize-wsdl desc1))
         (desc2 (cl-wsdl:parse-wsdl xml)))
    (is (= (length (cl-wsdl:wsdl-description-bindings desc1))
           (length (cl-wsdl:wsdl-description-bindings desc2))))
    (is (string= (cl-wsdl:wsdl-binding-name
                  (first (cl-wsdl:wsdl-description-bindings desc1)))
                 (cl-wsdl:wsdl-binding-name
                  (first (cl-wsdl:wsdl-description-bindings desc2)))))))

(test serialize-wsdl-roundtrip-service
  "serialize-wsdl output can be re-parsed to recover service and endpoint data."
  (let* ((desc1 (cl-wsdl:parse-wsdl +simple-wsdl+))
         (xml   (cl-wsdl:serialize-wsdl desc1))
         (desc2 (cl-wsdl:parse-wsdl xml)))
    (let ((svc1 (first (cl-wsdl:wsdl-description-services desc1)))
          (svc2 (first (cl-wsdl:wsdl-description-services desc2))))
      (is (string= (cl-wsdl:wsdl-service-name svc1)
                   (cl-wsdl:wsdl-service-name svc2)))
      (is (string= (cl-wsdl:wsdl-endpoint-address
                    (first (cl-wsdl:wsdl-service-endpoints svc1)))
                   (cl-wsdl:wsdl-endpoint-address
                    (first (cl-wsdl:wsdl-service-endpoints svc2))))))))

(test wsdl-find-interface-found
  "wsdl-find-interface returns the matching interface struct."
  (let* ((desc  (cl-wsdl:parse-wsdl +simple-wsdl+))
         (iface (cl-wsdl:wsdl-find-interface desc "HelloInterface")))
    (is (cl-wsdl:wsdl-interface-p iface))
    (is (string= "HelloInterface" (cl-wsdl:wsdl-interface-name iface)))))

(test wsdl-find-interface-not-found
  "wsdl-find-interface returns NIL when the name does not exist."
  (let ((desc (cl-wsdl:parse-wsdl +simple-wsdl+)))
    (is (null (cl-wsdl:wsdl-find-interface desc "NoSuchInterface")))))

(test wsdl-find-binding-found
  "wsdl-find-binding returns the matching binding struct."
  (let* ((desc    (cl-wsdl:parse-wsdl +simple-wsdl+))
         (binding (cl-wsdl:wsdl-find-binding desc "HelloBinding")))
    (is (cl-wsdl:wsdl-binding-p binding))
    (is (string= "HelloBinding" (cl-wsdl:wsdl-binding-name binding)))))

(test wsdl-find-service-found
  "wsdl-find-service returns the matching service struct."
  (let* ((desc    (cl-wsdl:parse-wsdl +simple-wsdl+))
         (service (cl-wsdl:wsdl-find-service desc "HelloService")))
    (is (cl-wsdl:wsdl-service-p service))
    (is (string= "HelloService" (cl-wsdl:wsdl-service-name service)))))

(test wsdl-error-condition
  "wsdl-error condition reports message and path correctly."
  (let ((err (make-condition 'cl-wsdl:wsdl-error
                             :message "bad WSDL"
                             :path "wsdl:description")))
    (is (string= "bad WSDL" (cl-wsdl:wsdl-error-message err)))
    (is (string= "wsdl:description" (cl-wsdl:wsdl-error-path err)))
    (is (search "bad WSDL" (format nil "~a" err)))))

(test wsdl-error-condition-no-path
  "wsdl-error condition without a path omits the path in the message."
  (let ((err (make-condition 'cl-wsdl:wsdl-error :message "test")))
    (is (null (cl-wsdl:wsdl-error-path err)))
    (is (search "test" (format nil "~a" err)))))

(test wsdl-description-struct
  "make-wsdl-description creates a struct with default empty slots."
  (let ((d (cl-wsdl:make-wsdl-description)))
    (is (cl-wsdl:wsdl-description-p d))
    (is (null (cl-wsdl:wsdl-description-target-namespace d)))
    (is (null (cl-wsdl:wsdl-description-imports d)))
    (is (null (cl-wsdl:wsdl-description-interfaces d)))
    (is (null (cl-wsdl:wsdl-description-bindings d)))
    (is (null (cl-wsdl:wsdl-description-services d)))))

(test parse-wsdl-no-target-namespace
  "parse-wsdl accepts a description without targetNamespace."
  (let ((desc (cl-wsdl:parse-wsdl
               "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\">
</wsdl:description>")))
    (is (cl-wsdl:wsdl-description-p desc))
    (is (null (cl-wsdl:wsdl-description-target-namespace desc)))))

(test parse-wsdl-multiple-interfaces
  "parse-wsdl collects all wsdl:interface children in order."
  (let* ((desc (cl-wsdl:parse-wsdl
                "<?xml version=\"1.0\"?>
<wsdl:description xmlns:wsdl=\"http://www.w3.org/ns/wsdl\"
                  targetNamespace=\"http://example.com/\">
  <wsdl:interface name=\"Alpha\" />
  <wsdl:interface name=\"Beta\" />
  <wsdl:interface name=\"Gamma\" />
</wsdl:description>"))
         (ifaces (cl-wsdl:wsdl-description-interfaces desc)))
    (is (= 3 (length ifaces)))
    (is (string= "Alpha" (cl-wsdl:wsdl-interface-name (first  ifaces))))
    (is (string= "Beta"  (cl-wsdl:wsdl-interface-name (second ifaces))))
    (is (string= "Gamma" (cl-wsdl:wsdl-interface-name (third  ifaces))))))
