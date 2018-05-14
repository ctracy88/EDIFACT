<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML INVOIC into Toymaster D01B Invoice.
	
	Input: TC XML Invoice.
	Output: Toymaster EDIFACT D01B Invoice.
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: February 10, 2016
		
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
				<Field> <!-- UNH 2.5 -->
					<xsl:value-of select="UNH/AssociationCode" />
				</Field>
				<Field/> <!-- UNH 2.6 -->
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
			<xsl:if test="string-length(DTM/TaxPointDate) &gt; 0">
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>131</Field>
                    <Field>
                        <xsl:value-of select="DTM/TaxPointDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			</xsl:if>
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
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>INV</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/Note" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(FTX/TermsofPaymentNote) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAI</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/TermsofPaymentNote" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(RFF/RefDelNoteNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>DQ</Field>
					<Field>
						<xsl:value-of select="RFF/RefDelNoteNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/InternalOrderNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>VN</Field>
					<Field>
						<xsl:value-of select="RFF/InternalOrderNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/BatchNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ALL</Field>
					<Field>
						<xsl:value-of select="RFF/BatchNum" />
					</Field>
				</Field>
			</RFF>
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
				<xsl:if test="string-length(RFF/DTM/PODate) &gt; 0">
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
				</xsl:if>
			</RFF>
			</xsl:if>
			<NAD> <!-- NAD.BY -->
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.BY/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Name" />
					</Field>
					<Field>
					</Field>
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
					<xsl:value-of select="NAD.BY/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/Country" />
				</Field>
				<xsl:if test="string-length(NAD.BY/RFF/VatRegNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.BY/RFF/VatRegNum" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
			</NAD>
			<xsl:if test="string-length(NAD.IV/Name) &gt; 0">
			<NAD> <!-- NAD.IV -->
                <mapper:incVar name="segmentCount" />
                <Field>IV</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.IV/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.IV/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.IV/Name" />
					</Field>
					<Field>
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address2" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address3" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address4" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/Country" />
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
			<NAD> <!-- NAD.DP -->
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.DP/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.DP/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.DP/Name" />
					</Field>
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
					<xsl:value-of select="NAD.DP/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.DP/Country" />
				</Field>
				<xsl:if test="string-length(NAD.DP/RFF/LocationCode) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>IA</Field>
						<Field>
							<xsl:value-of select="NAD.IV/RFF/LocationCode" />
						</Field>				
					</Field>	
				</RFF>
				</xsl:if>
			</NAD>
            <NAD> <!-- NAD.SU -->
               <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.SU/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Name2" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SU/Address2" />
					</Field>
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
						<Field>IA</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/VendorNum" />
						</Field>				
					</Field>	
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/TaxGSTRegistrationAmount" />
						</Field>				
					</Field>	
				</RFF>
			</NAD>
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
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>13</Field>
						<Field>
							<xsl:value-of select="PAT/DTM/TermsNetDueDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>12</Field>
						<Field>
							<xsl:value-of select="PAT/PCD/InterestCharge" />
						</Field>
					</Field>
				</PCD>
			</PAT>
			</xsl:if>
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
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/PIA/ProductIDType" />
							</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/BuyerItemNum" />
								</Field>
								<Field>BP</Field>							
							</Field>				
						</PIA>
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/PIA/ProductIDType" />
							</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/ItemModelNumber" />
								</Field>
								<Field>SA</Field>							
							</Field>				
						</PIA>
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>F</Field>
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
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>47</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/Qty" />
								</Field>
								<Field>EA</Field>
							</Field>
						</QTY>
						<xsl:if test="string-length(LIN/FTX/CreditReason) &gt; 0">
						<FTX>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>ACD</Field>
								<Field/>
								<Field/>
								<Field>
									<Field>
									<xsl:value-of select="LIN/FTX/CreditReason" />
									</Field>
								</Field>
							</Field>
						</FTX>
						</xsl:if>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>203</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/LineItemAmount" />
								</Field>
							</Field>
						</MOA>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAA</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/Price" />
								</Field>
							</Field>
						<xsl:if test="string-length(LIN/PRI/Price) &gt; 0">
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAB</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/GrossPriceDetails" />
								</Field>
							</Field>
						</PRI>
						</xsl:if>
						<xsl:if test="string-length(LIN/RFF/ItemOrderNumber) &gt; 0">
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>ON</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/ItemOrderNumber" />
								</Field>
							</Field>
						</RFF>
						</xsl:if>
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>IV</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/ItemOrderNumber" />
								</Field>
							</Field>
						</RFF>
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
							<Field>
								<Field>
									<xsl:value-of select="LIN/TAX/ItemTaxType" />
								</Field>
							</Field>
							<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>124</Field>
								<Field>
									<xsl:value-of select="LIN/TAX/MOA/TaxAmount" />
								</Field>
							</Field>
							</MOA>
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
						<mapper:getVar name="segmentCount" />
					</Field>
				</Field>
			</CNT>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>86</Field>
					<Field>
						<xsl:value-of select="MOA/InvoiceTotalAmount" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>79</Field>
					<Field>
						<xsl:value-of select="MOA/MessageTotal" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>125</Field>
					<Field>
						<xsl:value-of select="MOA/TaxableAmt" />
					</Field>
				</Field>
			</MOA>
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
					<xsl:value-of select="TAX/VATRate" />
				</Field>
			</Field>
				<Field>
					<Field>
						<xsl:value-of select="TAX/VATTaxCategory" />
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