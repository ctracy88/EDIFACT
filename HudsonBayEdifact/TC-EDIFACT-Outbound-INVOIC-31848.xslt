<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML INVOIC into Hudson Bay Edifact D96A Invoice.
	
	Input: TC XML Invoice.
	Output: The Iconic EDIFACT D96A Invoice.
	
	Author: Jen Ciambro	
	Version: 1.0
	Creation Date: August 14, 2017
		
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
        <Document una=":+.? '" type="EDIFACT" wrapped="false">
            <xsl:attribute name="syntax">
                <xsl:value-of select="'UNOA'" />
            </xsl:attribute>
            <xsl:attribute name="version">
                <xsl:value-of select="'3'" />
            </xsl:attribute>
            <mapper:setVar name="messageCount">0</mapper:setVar> <!-- Segment counter do not remove -->
            <UNB>
                <Field> <!-- UNB 1-->
                    <Field>UNOC</Field> <!-- UNB 1.1-->
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
                <Field></Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field>1</Field>
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
				<Field>EAN008</Field> <!-- UNH 2.5 -->
				<Field></Field> <!-- UNH 2.6 -->
				<Field/> <!-- UNH 2.7 -->
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
                    <Field/>
                    <Field/>
				</Field>
                <Field>
                    <xsl:value-of select="BGM/DocNum" />
                </Field>
                <Field>
					<xsl:value-of select="BGM/MsgFunction" />
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
			<xsl:if test="string-length(DTM/DateRequestedDelivery) &gt; 0">
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
			</xsl:if>
			<xsl:if test="string-length(FTX/TermsofPaymentNote) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>SUR</Field>
				<Field>1</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/TermsofPaymentNote" />
					</Field>
				</Field>
				<Field>DE</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(FTX/TermsofPaymentNote) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>REG</Field>
				<Field></Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/TermsofPaymentNote" />
					</Field>
				</Field>
				<Field>DE</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(RFF/TransportDocNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CT</Field>
					<Field>
						<xsl:value-of select="RFF/TransportDocNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="RFF/PONum" />
					</Field>
				</Field>
			</RFF>
			<xsl:if test="string-length(RFF/RefDelNotNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>DQ</Field>
					<Field>
						<xsl:value-of select="RFF/RefDelNotNum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/RefDelNotNumDate" />
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
					<Field>ABO</Field>
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
			            <NAD> <!-- NAD.SU -->
               <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field/>
                    <Field>9</Field>
				</Field>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>API</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/VendorNum" />
						</Field>				
					</Field>	
				</RFF>
				<xsl:if test="string-length(NAD.SU/RFF/TaxGSTRegistrationAmount) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/TaxGSTRegistrationAmount" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(NAD.SU/RFF/ReferenceMediaCode) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>FC</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/ReferenceMediaCode" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
			</NAD>
			<NAD> <!-- NAD.BY -->
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field/>
                    <Field>9</Field>
				</Field>
				<xsl:if test="string-length(NAD.BY/RFF/ReferenceMediaCode) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.BY/RFF/VATRegNum" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
			</NAD>
			<NAD> <!-- NAD.DP -->
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.DP/Code" />
                    </Field>
                    <Field/>
                    <Field>9</Field>
				</Field>
				<xsl:if test="string-length(NAD.DP/RFF/LocationCode) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>IT</Field>
						<Field>
							<xsl:value-of select="NAD.DP/RFF/LocationCode" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
				<xsl:if test="string-length(NAD.DP/CTA/ContactName) &gt; 0">
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>PD</Field>
					<Field>
						<xsl:value-of select="NAD.DP/CTA/ContactName" />
					</Field>
				</CTA>
				</xsl:if>
			</NAD>
			<xsl:if test="string-length(NAD.IV/Code) &gt; 0">
			<NAD> <!-- NAD.IV -->
                <mapper:incVar name="segmentCount" />
                <Field>IV</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.IV/Code" />
                    </Field>
                    <Field/>
                    <Field>9</Field>
				</Field>
				<xsl:if test="string-length(NAD.IV/RFF/ReferenceCode) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.IV/RFF/ReferenceCode" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
			</NAD>
			</xsl:if>
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
				<Field>
					<xsl:value-of select="TAX/ValueAddedTaxType" />
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
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/LineNum" />
						</Field>
						<Field/>
						<Field>
							<Field>
								<xsl:value-of select="LIN/EANNumber" />
							</Field>
							<Field>EN</Field>
						</Field>
						<xsl:if test="string-length(LIN/PIA/BuyerItemNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/BuyerItemNum" />
								</Field>
								<Field>IN</Field>							
							</Field>				
						</PIA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PIA/ItemModelNumber) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/ItemModelNumber" />
								</Field>
								<Field>SA</Field>							
							</Field>				
						</PIA>
						</xsl:if>
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>A</Field>
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
						<xsl:if test="string-length(LIN/PIA/ItemModelNumber) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/TradedUnitedDescription" />
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
								<Field>
									<xsl:value-of select="LIN/QTY/UOM" />
								</Field>
							</Field>
						</QTY>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>203</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/LineItemAmt" />
								</Field>
							</Field>
						</MOA>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAB</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/Price" />
								</Field>
								<Field/>
								<Field/>
								<Field>1</Field>
								<Field>PCE</Field>
							</Field>
						</PRI>
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
									<xsl:value-of select="LIN/TAX/VATTaxCategory" />
								</Field>
							</Field>
						</TAX>
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
					<Field>
						<xsl:value-of select="count(//Item)" />
					</Field>
				</Field>
			</CNT>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>77</Field>
					<Field>
						<xsl:value-of select="MOA/Total" />
					</Field>
				</Field>
			</MOA>
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