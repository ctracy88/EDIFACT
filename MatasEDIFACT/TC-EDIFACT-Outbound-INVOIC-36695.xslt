<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML INVOIC into a Volvo D96A Invoice.
	
	Input: Generic XML Invoice.
	Output: Volvo D96A Invoice.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: July 22, 2016
		
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
                <Field>9</Field> <!-- BGM 3 -->
				<Field/> <!-- BGM 4 -->
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
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>AAU</Field>
					<Field>
						<xsl:value-of select="RFF/DespatchNum" />
					</Field>
				</Field>
			</RFF>
			<xsl:if test="string-length(RFF/CustomerRefNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CR</Field>
					<Field>
						<xsl:value-of select="RFF/CustomerRefNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="RFF/BuyerOrderNum" />
					</Field>
				</Field>
				<xsl:if test="string-length(RFF/DTM/InternalOrderDate) &gt; 0">
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
				</xsl:if>
			</RFF>
			<xsl:if test="string-length(RFF/PromotionNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>PD</Field>
					<Field>
						<xsl:value-of select="RFF/PromotionNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/ReceiptNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>POR</Field>
					<Field>
						<xsl:value-of select="RFF/ReceiptNum" />
					</Field>
				</Field>
				<xsl:if test="string-length(RFF/DTM/ReceiptDate) &gt; 0">
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
				</xsl:if>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/SellerInvoiceNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>SS</Field>
					<Field>
						<xsl:value-of select="RFF/SellerInvoiceNum" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/RefDelNoteNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ZZZ</Field>
					<Field>
						<xsl:value-of select="RFF/RefDelNoteNum" />
					</Field>
				</Field>
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
                    <Field/>
                    <Field>
						9
					</Field>
				</Field>
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>OC</Field>
					<Field>
						<Field></Field>
						<Field>
							<xsl:value-of select="NAD.BY/CTA/InfoContact" />
						</Field>
					</Field>
					<xsl:if test="string-length(NAD.BY/CTA/COM/BuyerPhone) &gt; 0">
					<COM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>
								<xsl:value-of select="NAD.BY/CTA/COM/BuyerPhone" />
							</Field>
							<Field>TE</Field>
						</Field>
					</COM>
					</xsl:if>
					<xsl:if test="string-length(NAD.BY/CTA/COM/BuyerEmail) &gt; 0">
					<COM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>
								<xsl:value-of select="NAD.BY/CTA/COM/BuyerEmail" />
							</Field>
							<Field>EM</Field>
						</Field>
					</COM>
					</xsl:if>
				</CTA>
			</NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <!-- SU = Supplier -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field/>
                    <Field>
						9
					</Field>
				</Field>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/VATRegistrationNum" />
						</Field>
					</Field>
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>PY</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/ReferenceMediaCode" />
						</Field>
					</Field>
				</RFF>
				<xsl:if test="string-length(NAD.SU/CTA/COM/Email) &gt; 0">
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>DL</Field>
					<COM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>
								<xsl:value-of select="NAD.SU/CTA/COM/Phone" />
							</Field>
							<Field>TE</Field>
						</Field>
					</COM>		
					<COM>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>
								<xsl:value-of select="NAD.SU/CTA/COM/Email" />
							</Field>
							<Field>EM</Field>
						</Field>
					</COM>
				</CTA>
				</xsl:if>
			</NAD>
			<xsl:if test="string-length(NAD.FG/Name) &gt; 0">
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <Field>
					<Field>
						<xsl:value-of select="NAD.FG/CodeType" />
					</Field>
					<Field/>
					<Field>
						<xsl:value-of select="NAD.FG/Code" />
					</Field>
				</Field>
                <Field/>
				<Field>
					<xsl:value-of select="NAD.FG/Name" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.FG/Address1" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.FG/City" />
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.FG/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.FG/Country" />
				</Field>
			</NAD>
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>
						<xsl:value-of select="CUX/CurrencyType" />
					</Field>
					<Field>
						<xsl:value-of select="CUX/Currency" />
					</Field>
					<Field>
						<xsl:value-of select="CUX/CurrencyQual" />
					</Field>
				</Field>
			</CUX>
			<PAT>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PAT/Type" />
				</Field>
				<xsl:if test="string-length(PAT/DTM/TermsNetDueDate) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>13</Field>
						<Field>
							<xsl:value-of select="PAT/DTM/TermsNetDueDate" />
						</Field>
					</Field>
				</DTM>
				</xsl:if>
			</PAT>
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
						<xsl:if test="string-length(LIN/PIA/NationalGroupProduct) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
								<xsl:value-of select="LIN/PIA/NationalGroupProduct" />
								</Field>
								<Field>GN</Field>							
							</Field>				
						</PIA>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/Desc) &gt; 0">
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
						</xsl:if>
						<xsl:if test="string-length(LIN/QTY/Qty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>46</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/Qty" />
								</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/QTY/ReceivedQty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>47</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/ReceivedQty" />
								</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/FTX/CreditReason) &gt; 0">
						<FTX>
							<Field>ZZZ</Field>
							<Field>1</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/FTX/CreditReason" />
							</Field>
						</FTX>
						</xsl:if>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>203</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/GoodsItemTotal" />
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
									<xsl:value-of select="LIN/TAX/ItemTaxExemptCode" />
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
						<xsl:if test="string-length(LIN/ALC/AllowChargeIndicator) &gt; 0">
						<ALC>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/ALC/AllowChargeIndicator" />
							</Field>
							<xsl:if test="string-length(LIN/ALC/MOA/AllowChargeAmount) &gt; 0">
							<MOA>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>8</Field>
									<Field>
										<xsl:value-of select="LIN/ALC/MOA/AllowChargeAmount" />
									</Field>
								</Field>
							</MOA>
							</xsl:if>
						</ALC>
						</xsl:if>
					</LIN>
                </xsl:for-each>
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>66</Field>
					<Field>
						<xsl:value-of select="MOA/TotalInvAddAmount" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>77</Field>
					<Field>
						<xsl:value-of select="MOA/Total" />
					</Field>
				</Field>
			</MOA>
			<xsl:if test="string-length(MOA/TotalofLineItemsAmt) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>79</Field>
					<Field>
						<xsl:value-of select="MOA/TotalofLineItemsAmt" />
					</Field>
				</Field>
			</MOA>
			</xsl:if>
			<xsl:if test="string-length(MOA/MessageTotal) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>86</Field>
					<Field>
						<xsl:value-of select="MOA/MessageTotal" />
					</Field>
				</Field>
			</MOA>
			</xsl:if>
			<xsl:if test="string-length(MOA/TaxableAmt) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>125</Field>
					<Field>
						<xsl:value-of select="MOA/TaxableAmt" />
					</Field>
				</Field>
			</MOA>
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
						<xsl:value-of select="TAX/TotalVATPercent" />
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