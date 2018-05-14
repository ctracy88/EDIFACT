<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML INVOIC into a EANCOM D96A Invoice.
	
	Input: Generic XML Invoice.
	Output: EANCOM D96A Invoice.
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: 10-Apr-2017
		
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension" xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension" xmlns:edifact="com.css.base.xml.xslt.ext.edi.XsltParsedEdifactEdiExtension" xmlns:mapper="com.api.tx.MapperEngine" extension-element-prefixes="date mapper str edifact">
    <xsl:output method="xml" />
    <xsl:param name="SenderEnvelopeQualifier" />
    <xsl:param name="TestMode" />
    <!-- true if to override the partner default -->
    <xsl:param name="CustomerCodeForSupplier" />
    <!-- Optional if not supplied in the generic XML -->
    <xsl:param name="Network" />
    <!-- AS2 or TGMS. If not specified then it defaults to TGMS -->
    <xsl:param name="Container" />
    <!-- If not in the Type/Customers or Type/Suppliers then you can use this. Set to CHEP or EURO -->
    <xsl:param name="BoxType" />
    <!-- If not in the SuppliedIn then you can use this. Set to TRAY or BOX -->
    <xsl:param name="NetworkPassword" />
    <xsl:param name="UseConsolidator" select="'true'" />
    <!-- Additional text to include within the batch reference stored in the property files.
			Useful if more than one account exists on the same supplier ANA. -->
    <xsl:param name="BatchRefText" />
    <xsl:template match="/">
        <xsl:apply-templates select="Batch" />
    </xsl:template>
    <xsl:template match="Batch">
		
		<xsl:variable name="receiverANA" select="/Batch/Invoice[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/Invoice[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/ASN[1]/Supplier/CustomersCode" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <Document type="EDIFACT" wrapped="false">
            <xsl:attribute name="syntax">
                <xsl:value-of select="'UNOA'" />
            </xsl:attribute>
            <xsl:attribute name="version">
                <xsl:value-of select="'3'" />
            </xsl:attribute>
            <mapper:setVar name="messageCount">0</mapper:setVar> <!-- Segment counter do not remove -->
            <UNB>
                <Field> <!-- UNB 1-->
                    <Field>UNOA</Field> <!-- UNB 1.1-->
                    <Field>3</Field> <!-- UNB 1.2-->
                </Field>
                <Field> <!-- UNB 2-->
                    <Field> <!-- UNB 2.1-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field> <!-- UNB 2.2-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field> <!-- UNB 3.2-->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/ReceiverCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 4-->
                    <Field> <!-- UNB 4.1 -->
                        <xsl:value-of select="date:insert('yyMMdd')" />
                    </Field>
                    <Field> <!-- UNB 4.2 -->
                        <xsl:value-of select="date:insert('hhmm')" />
                    </Field>
                </Field> 
                <Field> <!-- UNB 5 -->
                    <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field>INVOIC</Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field /> <!-- UNB 9 -->
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="Batch/Invoice[1]/BatchReferences/test" />
                </Field>
                <xsl:apply-templates select="Invoice">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/Invoice[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="Invoice">
        <xsl:param name="batchRef" />
        <xsl:variable name="GenNumber">
            <xsl:value-of select="position()" />
        </xsl:variable>
        <xsl:variable name="MsgRefNum">
            <xsl:value-of select="UNH/MsgRefNum" />
        </xsl:variable>
        <mapper:incVar name="messageCount" />
        <mapper:setVar name="segmentCount">0</mapper:setVar>
        <UNH>
            <mapper:incVar name="segmentCount" />
             <Field> <!-- UNH 1 -->
                <xsl:value-of select="$MsgRefNum" />
            </Field>
            <Field> <!-- UNH 2 -->
                <Field> <!-- UNH 2.1 -->
					<xsl:value-of select="UNH/MsgType" />
				</Field>
                <Field> <!-- UNH 2.2 -->
					<xsl:value-of select="UNH/MsgVersion" />
				</Field>
                <Field> <!-- UNH 2.3 -->
					<xsl:value-of select="UNH/MsgReleaseNum" />
				</Field>
                <Field> <!-- UNH 2.4 -->
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
				<Field>EAN008</Field>
				<Field/> <!-- UNH 2.6 -->
				<Field/> <!-- UNH 2.7 -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field> <!-- BGM 1 -->
                    <Field> <!-- BGM 1.1 -->
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
                    <Field/> <!-- BGM 1.2 -->
                    <Field/> <!-- BGM 1.3-->
					<Field/> <!-- BGM 1.4 -->
				</Field>
                <Field> <!-- BGM 2 -->
                    <xsl:value-of select="BGM/DocNum" />
                </Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="DTM/InvDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>35</Field>
                    <Field>
						<xsl:value-of select="DTM/DateRequestedDelivery" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>4</Field>
                    <Field>
                        <xsl:value-of select="DTM/OrderDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>209</Field>
                    <Field>
                        <xsl:value-of select="DTM/ValutaDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<xsl:if test="string-length(ALI/CountryOfOrigin) &gt; 0">
			<ALI>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="ALI/CountryOfOrigin" />
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="ALI/SpecialCondition" />
				</Field>
			</ALI>
			</xsl:if>
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>ZZZ</Field>
				<Field/>
				<Field/>
				<Field>
					<xsl:value-of select="FTX/Note" />
				</Field>
			</FTX>
			</xsl:if>					
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>SUR</Field>
				<Field/>
				<Field/>
				<Field>
					<xsl:value-of select="FTX/SupplierNote" />
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(RFF/PONum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="RFF/PONum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/PODate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/VendorOrderNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>VN</Field>
					<Field>
						<xsl:value-of select="RFF/SupplierOrderNum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/InternalOrderDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/BuyerOrderNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CO</Field>
					<Field>
						<xsl:value-of select="RFF/BuyerOrderNum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/ReceiptDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/DeliveryNote) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>DQ</Field>
					<Field>
						<xsl:value-of select="RFF/DeliveryNote" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/FreightBillDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/SellerInvoiceNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>IV</Field>
					<Field>
						<xsl:value-of select="RFF/SellerInvoiceNum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/SupplierInvoiceDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/CustomerRefNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CR</Field>
					<Field>
						<xsl:value-of select="RFF/CustomerRefNum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/RefDelNoteNumDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <!-- BY = Buyer -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.BY/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BY/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/Country" />
				</Field>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>API</Field>
							<Field>
								<xsl:value-of select="NAD.BY/RFF/SellerVATNumber" />
							</Field>				
						</Field>
					</RFF>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>IT</Field>
							<Field>
								<xsl:value-of select="NAD.BY/RFF/ReferenceMediaCode" />
							</Field>
						</Field>							
					</RFF>
            </NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <!-- SU = Supplier -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.SU/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/Country" />
				</Field>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>VA</Field>
							<Field>
								<xsl:value-of select="NAD.SU/RFF/TaxGSTRegistrationAmount" />
							</Field>				
						</Field>
					</RFF>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>FC</Field>
							<Field>
								<xsl:value-of select="NAD.SU/RFF/VendorNum" />
							</Field>
						</Field>							
					</RFF>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>API</Field>
							<Field>
								<xsl:value-of select="NAD.SU/RFF/ReferenceMediaCode" />
							</Field>
						</Field>							
					</RFF>
					<CTA>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>CR</Field>
							<Field>
								<xsl:value-of select="NAD.SU/CTA/ContactName" />
							</Field>
						</Field>
						<COM>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>
									<xsl:value-of select="NAD.SU/COM/Phone" />
								</Field>
								<Field>TE</Field>
							</Field>
						</COM>
						<COM>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>
									<xsl:value-of select="NAD.SU/COM/Email" />
								</Field>
								<Field>EM</Field>
							</Field>
						</COM>
						<COM>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>
									<xsl:value-of select="NAD.SU/COM/Fax" />
								</Field>
								<Field>FX</Field>
							</Field>
						</COM>
					</CTA>
            </NAD>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <!-- SE = Seller -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.DP/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.DP/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.DP/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.DP/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.DP/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.DP/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.DP/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.DP/Country" />
				</Field>
            </NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>IV</Field>
                <!-- IV = Invoice -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.IV/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.IV/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/Country" />
				</Field>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>IT</Field>
							<Field>
								<xsl:value-of select="NAD.IV/RFF/ReferenceCode" />
							</Field>
						</Field>
					</RFF>
			</NAD>
			<TAX>
			<mapper:incVar name="segmentCount" />
				<Field>7</Field>
				<Field>VAT</Field>
				<Field/>
				<Field/>
				<Field>
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="TAX/ValueAddedTaxPercent" />
					</Field>
				</Field>
			</TAX>
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>2</Field>
					<Field>
					<xsl:value-of select="CUX/Currency" />
					</Field>
					<Field>4</Field>
				</Field>
			</CUX>
			<PAT>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PAT/Type" />
				</Field>
				<Field></Field>
				<Field>
					<Field>
						<xsl:value-of select="PAT/BasedOn" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/TimeRelation" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/TypeOfPeriod" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/NumOfPeriods" />
					</Field>
				</Field>
				<xsl:if test="string-length(PCD/PercentType) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>12</Field>
						<Field>
							<xsl:value-of select="DTM/TermsDiscountDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				</xsl:if>
				<xsl:if test="string-length(PCD/PercentType) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>13</Field>
						<Field>
							<xsl:value-of select="DTM/TermsNetDueDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				</xsl:if>
				<xsl:if test="string-length(PCD/PercentType) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>
							<xsl:value-of select="PCD/PercentType" />
						</Field>
						<Field>
							<xsl:value-of select="PCD/PenaltyPercent" />
						</Field>
						<Field></Field>
					</Field>
				</PCD>
				</xsl:if>
			</PAT>
			<xsl:if test="string-length(TDT/TransportStageQual) &gt; 0">
			<TDT>
			<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
				<Field/>
				<Field>
					<Field/>
					<Field>
						<xsl:value-of select="TDT/ModeOfTransport" />
					</Field>
				</Field>
			</TDT>
			</xsl:if>
			<xsl:if test="string-length(TOD/TermsOfDelivery) &gt; 0">
			<TOD>
			<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="TOD/TermsOfDelivery" />
				</Field>
				<Field/>
				<Field>
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="TOD/DeliveryorTransportConditions" />
					</Field>
				</Field>
			</TOD>
			</xsl:if>
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/LineNum" />
						</Field>
						<Field></Field>
						<Field>
							<Field>
							<xsl:value-of select="LIN/EANNumber" />
							</Field>
							<xsl:if test="string-length(LIN/EANNumber) &gt; 0">
							<Field>EN</Field>
							</xsl:if>
						</Field>
						<xsl:if test="string-length(LIN/PIA/ItemModelNumber) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>5</Field>
							<Field>
								<Field>
								<xsl:value-of select="LIN/PIA/ItemModelNumber" />
								</Field>
								<Field>SA</Field>							
							</Field>				
						</PIA>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/Desc) &gt; 0">
						<IMD>
						<mapper:incVar name="segmentCount" />
							<Field>F</Field>
							<Field/>
							<Field/>
							<Field>
								<Field/>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/IMD/Desc" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/SizeDesc) &gt; 0">
						<IMD>
						<mapper:incVar name="segmentCount" />
							<Field>F</Field>
							<Field>98</Field>
							<Field/>
							<Field>
								<Field/>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/IMD/SizeDesc" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/ColorDesc) &gt; 0">
						<IMD>
						<mapper:incVar name="segmentCount" />
							<Field>F</Field>
							<Field>35</Field>
							<Field/>
							<Field>
								<Field/>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/IMD/ColorDesc" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>47</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/Qty" />
								</Field>
								<Field>PCE</Field>
							</Field>
						</QTY>
						<xsl:if test="string-length(LIN/QTY/ConsumerUnitsQty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>192</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/ConsumerUnitsQty" />
								</Field>
								<Field>PCE</Field>
							</Field>
						</QTY>
						</xsl:if>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>203</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/GoodsItemTotal" />
								</Field>
								<Field/>								
								<Field></Field>
							</Field>
						</MOA>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAA</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/Price" />
								</Field>
								<Field>CT</Field>
								<Field></Field>
								<Field>
									<xsl:value-of select="LIN/PRI/PriceBasis" />
								</Field>
								<Field>PCE</Field>
							</Field>
						</PRI>
					</LIN>
                </xsl:for-each>
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>
			<CNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>2</Field>
                    <!-- 2 = total number of lines -->
                    <Field>
                        <xsl:value-of select="count(Item)" />
                    </Field>
                </Field>
            </CNT>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>77</Field>
					<Field>
						<xsl:value-of select="MOA/TotalofLineItemsAmt" />
					</Field>
					<Field>GBP</Field>
					<Field>4</Field>
				</Field>
			</MOA>
			<TAX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>7</Field>
					<Field>VAT</Field>
					<Field>
						<Field></Field>
						<Field></Field>
						<Field></Field>
						<Field>
						<xsl:value-of select="TAX/TotalVATPercent" />
						</Field>
					</Field>
				</Field>
				<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>124</Field>
					<Field>
						<xsl:value-of select="TAX/MOA/VATAmt" />
					</Field>
				</Field>
				</MOA>
				<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>125</Field>
					<Field>
						<xsl:value-of select="TAX/MOA/TaxableAmt" />
					</Field>
				</Field>
				</MOA>
			</TAX>
            <UNT>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <mapper:getVar name="segmentCount" />
                </Field>
                <!-- number of segments in message -->
                <Field>
                    <xsl:value-of select="$MsgRefNum" />
                </Field>
                <!-- UNH reference number -->
            </UNT>
        </UNH>
    </xsl:template>
 </xsl:stylesheet>