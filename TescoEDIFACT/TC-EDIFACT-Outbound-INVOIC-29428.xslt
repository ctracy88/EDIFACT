<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML INVOIC into a EANCOM D96A Invoice.
	
	Input: Generic XML Invoice.
	Output: EANCOM D96A Invoice.
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: 17-Jan-2017
		
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
				<Field> <!-- UNH 2.5 -->
					<xsl:value-of select="UNH/AssociationCode" />
				</Field>
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
                <Field> <!-- BGM 3 -->
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
			<xsl:if test="string-length(RFF/RefDelNoteNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>DQ</Field>
					<Field>
						<xsl:value-of select="RFF/RefDelNoteNum" />
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
			<xsl:if test="string-length(RFF/DespatchNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>AAK</Field>
					<Field>
						<xsl:value-of select="RFF/DespatchNum" />
					</Field>
				</Field>
				<DTM>
				<mapper:incVar name="segmentCount" />
                <Field>
                    <Field>171</Field>
                    <Field>
                        <xsl:value-of select="RFF/DTM/DespatchDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
				</DTM>
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
				<DTM>
				<mapper:incVar name="segmentCount" />
                <Field>
                    <Field>171</Field>
                    <Field>
                        <xsl:value-of select="RFF/DTM/BatchDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
				</DTM>
			</RFF>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>PDR</Field>
					<Field>
						<xsl:value-of select="RFF/ReceiptNum" />
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
			<xsl:if test="string-length(RFF/InternalOrderNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>VN</Field>
					<Field>
						<xsl:value-of select="RFF/InternalOrderNum" />
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
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SE</Field>
                <!-- SE = Seller -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SE/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.SE/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SE/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SE/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SE/Country" />
				</Field>
					<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>VA</Field>
							<Field>
								<xsl:value-of select="NAD.SE/RFF/VATRegNum" />
							</Field>				
						</Field>
					</RFF>
            </NAD>
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
						<xsl:value-of select="NAD.BY/Address" />
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
					<xsl:value-of select="NAD.BY/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BY/Country" />
				</Field>
				<RFF>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>VA</Field>
							<Field>
								<xsl:value-of select="NAD.BY/RFF/VATRegNum" />
							</Field>				
						</Field>
					</RFF>
            </NAD>
			 <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SN</Field>
                <!-- IV = Invoice -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SN/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.SN/Name" />
				</Field>
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
			<xsl:if test="string-length(CUX/TargetCurrency) &gt; 0">
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>3</Field>
					<Field>
					<xsl:value-of select="CUX/TargetCurrency" />
					</Field>
					<Field>4</Field>
					<Field>
					<xsl:value-of select="CUX/TargetCurrencyExchangeRate" />
					</Field>
				</Field>
				<DTM>
				<mapper:incVar name="segmentCount" />
                <Field>
                    <Field>134</Field>
                    <Field>
                        <xsl:value-of select="CUX/DTM.CUX/TargetCurrencyOrderDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
				</DTM>
			</CUX>
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
						<xsl:if test="string-length(IMD/Desc) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>F</Field>
								<Field></Field>
								<Field></Field>
								<Field></Field>
								<Field>
									<xsl:value-of select="LIN/IMD/Desc" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(IMD/VariableWeightDescription) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>C</Field>
								<Field></Field>
								<Field>VQ</Field>
								<Field></Field>
								<Field>
									<xsl:value-of select="LIN/IMD/VariableWeightDescription" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(IMD/TradedUnitedDescription) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>C</Field>
								<Field></Field>
								<Field>TU</Field>
								<Field></Field>
								<Field>
									<xsl:value-of select="LIN/IMD/TradedUnitedDescription" />
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
							</Field>
						</QTY>
						<xsl:if test="string-length(LIN/QTY/CasesDelivered) &gt; 0">
						 <QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>46</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/CasesDelivered" />
								</Field>
							</Field>
						 </QTY>
						</xsl:if>
						 <QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>59</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/ConsumerUnitsQty" />
								</Field>
							</Field>
						 </QTY>
						 <xsl:if test="string-length(LIN/ALI/CountryOfOrigin) &gt; 0">
						 <ALI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>
									<xsl:value-of select="LIN/ALI/CountryOfOrigin" />
								</Field>
							</Field>
						 </ALI>
						</xsl:if>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>203</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/GoodsItemTotal" />
								</Field>
								<Field></Field>	
								<Field></Field>
							</Field>
						</MOA>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>66</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/NetLineAmount" />
								</Field>
								<Field></Field>	
								<Field></Field>
							</Field>
						</MOA>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAA</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/NetPriceDetails" />
								</Field>
								<Field></Field>
								<Field></Field>
							</Field>
						</PRI>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAB</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/GrossPriceDetails" />
								</Field>
								<Field></Field>
								<Field></Field>
							</Field>
						</PRI>
						<xsl:if test="string-length(LIN/RFF/ImportLicenseNum) &gt; 0">
						<RFF>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>IP</Field>
								<Field>
								<xsl:value-of select="LIN/RFF/ImportLicenseNum" />
								</Field>
							</Field>
							<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>171</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/DTM/ImportLicenseDate" />
								</Field>
								<Field>102</Field>
								</Field>
							</DTM>
						</RFF>
						</xsl:if>
						<xsl:if test="string-length(LIN/RFF/GovernmentRefNum) &gt; 0">
						<RFF>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>GN</Field>
								<Field>
								<xsl:value-of select="LIN/RFF/GovernmentRefNum" />
								</Field>
							</Field>
							<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>171</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/DTM/GovernmentRefDate" />
								</Field>
								<Field>102</Field>
								</Field>
							</DTM>
						</RFF>
						</xsl:if>
						<TAX>
						<mapper:incVar name="segmentCount" />
							<Field>7</Field>
							<Field>VAT</Field>
							<Field></Field>
							<Field></Field>
							<Field>
								<Field></Field>
								<Field></Field>
								<Field></Field>
								<Field>
								<xsl:value-of select="LIN/TAX/ItemTaxExemptCode" />
								</Field>
								<Field>
								<xsl:value-of select="LIN/TAX/VATTaxCategory" />
								</Field>
							</Field>
							<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>124</Field>
								<Field>
									<xsl:value-of select="LIN/TAX/MOA/TaxAmount" />
								</Field>
								<Field></Field>	
								<Field></Field>
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
                    <!-- 2 = total number of lines -->
                    <Field>
                        <xsl:value-of select="count(Item)" />
                    </Field>
                </Field>
            </CNT>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>9</Field>
					<Field>
						<xsl:value-of select="MOA/TotalofLineItemsAmt" />
					</Field>
					<Field></Field>
					<Field></Field>
				</Field>
			</MOA>
				<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>79</Field>
					<Field>
						<xsl:value-of select="MOA/MessageTotal" />
					</Field>
					<Field></Field>
					<Field></Field>
				</Field>
			</MOA>
			<TAX>
			<mapper:incVar name="segmentCount" />
				<Field>7</Field>
				<Field>VAT</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<Field></Field>
					<Field></Field>
					<Field></Field>
					<Field>
					<xsl:value-of select="TAX/TotalVATPercent" />
					</Field>
					<Field>
					<xsl:value-of select="TAX/VATTaxCategory" />
					</Field>
				<Field>
				<MOA>
				<mapper:incVar name="segmentCount" />
					<Field>
					<Field>124</Field>
					<Field>
						<xsl:value-of select="TAX/MOA/VATAmt" />
					</Field>
					<Field></Field>	
					<Field></Field>
					</Field>
				</MOA>
				<MOA>
				<mapper:incVar name="segmentCount" />
					<Field>
					<Field>125</Field>
					<Field>
						<xsl:value-of select="TAX/MOA/TaxableAmt" />
					</Field>
					<Field></Field>	
					<Field></Field>
					</Field>
				</MOA>
			</Tax>
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