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
                <Field/> <!-- BGM 3 -->
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
						<xsl:value-of select="NAD.BY/CodeType" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Name" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BY/Name2" />
					</Field>
				</Field>
				<xsl:if test="string-length(NAD.BY/RFF/VATRegNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
						<Field></Field>
							<Field>VA</Field>
							<Field>
								<xsl:value-of select="NAD.BY/RFF/VATRegNum" />
							</Field>				
					</RFF>
				</xsl:if>
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>AD</Field>
					<Field>
						<Field>
							<xsl:value-of select="NAD.BY/CTA/AccountingContact" />
						</Field>
					</Field>
				</CTA>
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>IC</Field>
					<Field>
						<Field>
							<xsl:value-of select="NAD.BY/CTA/InfoContact" />
						</Field>
					</Field>
				</CTA>
			</NAD>
			<xsl:if test="string-length(NAD.FG/Name) &gt; 0">
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>FG</Field>
                <Field/>
                <Field/>
				<Field>
					<xsl:value-of select="NAD.FG/Name" />
				</Field>
			</NAD>
			</xsl:if>
			<xsl:if test="string-length(NAD.FH/Name) &gt; 0">
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>FH</Field>
                <Field/>
                <Field/>
				<Field>
					<xsl:value-of select="NAD.FH/Name" />
				</Field>
			</NAD>
			</xsl:if>
			<xsl:if test="string-length(NAD.PE/Name) &gt; 0">
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>PE</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.PE/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.PE/CodeType" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.PE/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.PE/Name2" />
					</Field>
				</Field>
				<xsl:if test="string-length(NAD.PE/FII/AccountHolderNum) &gt; 0">
				<FII>
					<mapper:incVar name="segmentCount" />
						<Field>BF</Field>
						<Field>
							<Field>
								<xsl:value-of select="NAD.PE/FII/AccountHolderNum" />
							</Field>
						</Field>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="NAD.PE/FII/InstitutionName" />
							</Field>
						</Field>
				</FII>
				</xsl:if>
			</NAD>
			</xsl:if>			
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SE</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SE/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.SE/CodeType" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SE/Name" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SE/Name2" />
					</Field>
				</Field>
				<xsl:if test="string-length(NAD.SE/FII/AccountHolderNum) &gt; 0">
				<FII>
					<mapper:incVar name="segmentCount" />
						<Field>RH</Field>
						<Field>
							<Field>
								<xsl:value-of select="NAD.SE/FII/AccountHolderNum" />
							</Field>
						</Field>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="NAD.SE/FII/InstitutionName" />
							</Field>
						</Field>
				</FII>
				</xsl:if>
				<xsl:if test="string-length(NAD.SE/RFF/VATRegNum) &gt; 0">
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.SE/RFF/VATRegNum" />
						</Field>
					</Field>
				</RFF>
				</xsl:if>
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>AD</Field>
					<Field>
						<Field>
							<xsl:value-of select="NAD.SE/CTA/AccountingContact" />
						</Field>
					</Field>
				</CTA>
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
				<Field></Field>
				<Field>
					<Field>
						<xsl:value-of select="PAT/BasedOn" />
					</Field>
				</Field>
				<xsl:if test="string-length(PAT/DTM/TermsNetDueDate) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>140</Field>
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
								<xsl:value-of select="LIN/ItemHubNumber" />
							</Field>
							<Field>EN</Field>
						</Field>
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
						<xsl:if test="string-length(LIN/IMD/Desc) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
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
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>12</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/DespatchQty" />
								</Field>
							</Field>
						</QTY>
						<xsl:if test="string-length(LIN/QTY/ReceivedQty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>48</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/ReceivedQty" />
								</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/ALI/CountryOfOrigin) &gt; 0">
						<ALI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/ALI/CountryOfOrigin" />
							</Field>
						</ALI>
						</xsl:if>
						<xsl:if test="string-length(LIN/DTM/GoodsReceiptDate) &gt; 0">
						<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>50</Field>
								<Field>
									<xsl:value-of select="LIN/DTM/GoodsReceiptDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
						</xsl:if>
						<xsl:if test="string-length(LIN/DTM/TransCreateDate) &gt; 0">
						<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>97</Field>
								<Field>
									<xsl:value-of select="LIN/DTM/TransCreateDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
						</xsl:if>
						<xsl:if test="string-length(LIN/DTM/StartDate) &gt; 0">
						<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>194</Field>
								<Field>
									<xsl:value-of select="LIN/DTM/StartDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
						</xsl:if>
						<xsl:if test="string-length(LIN/DTM/EndDate) &gt; 0">
						<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>206</Field>
								<Field>
									<xsl:value-of select="LIN/DTM/EndDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
						</xsl:if>
						<xsl:if test="string-length(LIN/GIN/SerialNum) &gt; 0">
						<GIN>
							<mapper:incVar name="segmentCount" />
							<Field>BN</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/GIN/SerialNum" />
								</Field>
							</Field>
						</GIN>
						</xsl:if>
						<xsl:if test="string-length(LIN/GIN/EngineNum) &gt; 0">
						<GIN>
							<mapper:incVar name="segmentCount" />
							<Field>EE</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/GIN/EngineNum" />
								</Field>
							</Field>
						</GIN>
						</xsl:if>
						<xsl:if test="string-length(LIN/GIN/VINNum) &gt; 0">
						<GIN>
							<mapper:incVar name="segmentCount" />
							<Field>VV</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/GIN/VINNum" />
								</Field>
							</Field>
						</GIN>
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
								<Field>AAB</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/Price" />
								</Field>
							</Field>
						</PRI>
						<RFF>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>ON</Field>
								<Field>
								<xsl:value-of select="LIN/RFF/ItemOrderNumber" />
								</Field>
							</Field>
						</RFF>
						<xsl:if test="string-length(LIN/RFF/DespatchAdviceNum) &gt; 0">
						<RFF>
						<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAK</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/DespatchAdviceNum" />
								</Field>
							</Field>
							<xsl:if test="string-length(LIN/RFF/DTM/DespatchAdviceNumDate) &gt; 0">
							<DTM>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>171</Field>
									<Field>
										<xsl:value-of select="LIN/RFF/DTM/DespatchAdviceNumDate" />
									</Field>
									<Field>102</Field>
								</Field>
							</DTM>
							</xsl:if>
						</RFF>
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
						<NAD>
							<mapper:incVar name="segmentCount" />
							<Field>CN</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/NAD.CN/Code" />
								</Field>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/NAD.CN/CodeType" />
								</Field>
							</Field>
						</NAD>
						<xsl:if test="string-length(LIN/ALC/AllowChargeIndicator) &gt; 0">
						<ALC>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/ALC/AllowChargeIndicator" />
							</Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/ALC/SpecialServicesID" />
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
							<xsl:if test="string-length(LIN/ALC/TAX/AllowChargeTaxRate) &gt; 0">
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
										<xsl:value-of select="LIN/ALC/TAX/AllowChargeTaxRate" />
									</Field>
								</Field>
								<xsl:if test="string-length(LIN/ALC/TAX/MOA/AllowChargeTaxAmount) &gt; 0">
								<MOA>
									<mapper:incVar name="segmentCount" />
									<Field>
										<Field>124</Field>
										<Field>
											<xsl:value-of select="LIN/ALC/TAX/MOA/AllowChargeTaxAmount" />
										</Field>
									</Field>
								</MOA>
								</xsl:if>
							</TAX>
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
					<Field>77</Field>
					<Field>
						<xsl:value-of select="MOA/Total" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>79</Field>
					<Field>
						<xsl:value-of select="MOA/TotalofLineItemsAmt" />
					</Field>
				</Field>
			</MOA>
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
			<xsl:if test="string-length(MOA/TotalInvAddAmount) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>136</Field>
					<Field>
						<xsl:value-of select="MOA/TotalInvAddAmount" />
					</Field>
				</Field>
			</MOA>
			</xsl:if>
			<xsl:if test="string-length(MOA/MessageTotal) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>176</Field>
					<Field>
						<xsl:value-of select="MOA/MessageTotal" />
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