<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML INVOIC into The Iconic D01B Invoice.
	
	Input: TC XML Invoice.
	Output: The Iconic EDIFACT D01B Invoice.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: August 22, 2016
		
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
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>ZZZ</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/Note" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAK</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/PriceConditions" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>ABN</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/AccountingInformation" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
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
							<xsl:value-of select="RFF/DTM/PODate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/ShipmentRefNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ABO</Field>
					<Field>
						<xsl:value-of select="RFF/ShipmentRefNum" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/BOLDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/ContractNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CT</Field>
					<Field>
						<xsl:value-of select="RFF/ContractNum" />
					</Field>
				</Field>
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
						<Field>VA</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/SupplierBusinessNum" />
						</Field>				
					</Field>	
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>FC</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/ReferenceMediaCode" />
						</Field>				
					</Field>	
				</RFF>
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
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>YC1</Field>
						<Field>
							<xsl:value-of select="NAD.DP/RFF/BranchNum" />
						</Field>				
					</Field>	
				</RFF>
				<RFF>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>IT</Field>
						<Field>
							<xsl:value-of select="NAD.DP/RFF/InternalCustomerNum" />
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
						<xsl:value-of select="TAX/ValueAddedTaxRate" />
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
			<xsl:if test="string-length(ALC/MOA/FreightCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field>1</Field>
				<Field>
					<Field>FC</Field>
				</Field>
				<xsl:if test="string-length(ALC/MOA/FreightCharge) &gt; 0">
				<MOA>
					<Field>
						<Field>8</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/FreightCharge" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/AllowanceDiscount) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>A</Field>
				<Field>
					<xsl:value-of select="ALC/AllowanceDiscountDesc" />
				</Field>
				<Field/>
				<Field>1</Field>
				<Field>
					<Field>DI</Field>
				</Field>
				<xsl:if test="string-length(ALC/PCD/AllowanceDiscountPercent) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>3</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/AllowanceDiscountPercent" />
						</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(ALC/MOA/AllowanceDiscount) &gt; 0">
				<MOA>
					<Field>
						<Field>8</Field>
						<Field>
							<xsl:value-of select="ALC/MOA/AllowanceDiscount" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/RebateAllowance) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>A</Field>
				<Field>
					<xsl:value-of select="ALC/RebateAllowanceDesc" />
				</Field>
				<Field/>
				<Field/>
				<Field>RAA</Field>
				<xsl:if test="string-length(ALC/PCD/RebateAllowancePercent) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>3</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/RebateAllowancePercent" />
						</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(ALC/MOA/RebateAllowance) &gt; 0">
				<MOA>
					<Field>
						<Field>8</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/RebateAllowance" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</ALC>
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
								<xsl:value-of select="LIN/GTINUPCNum" />
							</Field>
							<Field>SRV</Field>
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
								<Field/>
								<Field>91</Field>
							</Field>				
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/BuyerItemNum" />
								</Field>
								<Field>IN</Field>
								<Field/>
								<Field>91</Field>
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
						<xsl:if test="string-length(LIN/IMD/ColorDescription) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field>35</Field>
							<Field>
								<Field/>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/IMD/ColorDescription" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/SizeDescription) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field>98</Field>
							<Field>
								<Field/>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/IMD/SizeDescription" />
								</Field>
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/CodedDesc1) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/CodedDesc1" />
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/CodedDesc2) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/CodedDesc2" />
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/CodedDesc3) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/CodedDesc3" />
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/IMD/CodedDesc4) &gt; 0">
						<IMD>
							<mapper:incVar name="segmentCount" />
							<Field>C</Field>
							<Field/>
							<Field>
								<xsl:value-of select="LIN/IMD/CodedDesc4" />
							</Field>
						</IMD>
						</xsl:if>
						<xsl:if test="string-length(LIN/QTY/Qty) &gt; 0">
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
						</xsl:if>
						<xsl:if test="string-length(LIN/QTY/ReceivedQty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>46</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/ReceivedQty" />
								</Field>
								<Field>PCE</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/FTX/ItemNote) &gt; 0">
						<FTX>
							<mapper:incVar name="segmentCount" />
							<Field>ZZZ</Field>
							<Field>1</Field>
							<Field/>
							<Field>
								<Field>
									<xsl:value-of select="LIN/FTX/ItemNote" />
								</Field>
							</Field>
						</FTX>
						</xsl:if>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>203</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/LineItemAmt" />
								</Field>
							</Field>
						</MOA>
						<xsl:if test="string-length(LIN/MOA/AllowanceChargeAmt) &gt; 0">
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>131</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/AllowanceChargeAmt" />
								</Field>
							</Field>
						</MOA>
						</xsl:if>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAB</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/Price" />
								</Field>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/PRI/PriceBasis" />
								</Field>
								<Field>PCE</Field>
							</Field>
						</PRI>
						<xsl:if test="string-length(LIN/TAX/GSTTax) &gt; 0">
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
									<xsl:value-of select="LIN/TAX/GSTTax" />
								</Field>
							</Field>
						</TAX>
						</xsl:if>
						<xsl:if test="string-length(LIN/ALC/MOA/AllowanceDiscountAmt) &gt; 0">
						<ALC>
							<mapper:incVar name="segmentCount" />
							<Field>A</Field>
							<Field/>
							<Field/>
							<Field>1</Field>
							<Field>
								<Field>DI</Field>
							</Field>
							<xsl:if test="string-length(LIN/ALC/MOA/AllowanceDiscountAmt) &gt; 0">
							<MOA>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>8</Field>
									<Field>
										<xsl:value-of select="LIN/ALC/MOA/AllowanceDiscountAmt" />
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
			<CNT>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>2</Field>
					<Field>
						<mapper:getVar name="segmentCount" />
					</Field>
				</Field>
			</CNT>
			<xsl:if test="string-length(MOA/InvoiceTotalAmount) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>77</Field>
					<Field>
						<xsl:value-of select="MOA/InvoiceTotalAmount" />
					</Field>
				</Field>
			</MOA>
			</xsl:if>
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
			<xsl:if test="string-length(MOA/TotalGSTAmount) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>124</Field>
					<Field>
						<xsl:value-of select="MOA/TotalGSTAmount" />
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
			<xsl:if test="string-length(MOA/TotalOtherCharges) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>131</Field>
					<Field>
						<xsl:value-of select="MOA/TotalOtherCharges" />
					</Field>
				</Field>
			</MOA>
			</xsl:if>
			<xsl:if test="string-length(MOA/RetailTotal) &gt; 0">
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>402</Field>
					<Field>
						<xsl:value-of select="MOA/RetailTotal" />
					</Field>
				</Field>
			</MOA>
			</xsl:if>
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