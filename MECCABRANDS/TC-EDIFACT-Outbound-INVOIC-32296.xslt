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
        <Document una=":+.? '" type="EDIFACT" wrapped="true">
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
				<Field>EAN011</Field> <!-- UNH 2.5 -->
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
					<Field>TAX INVOICE</Field>
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
			<xsl:if test="string-length(FTX/Note) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAI</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/Note" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(RFF/ShippingBOL) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>BM</Field>
					<Field>
						<xsl:value-of select="RFF/ShippingBOL" />
					</Field>
				</Field>
			</RFF>
			</xsl:if>
			<xsl:if test="string-length(RFF/ShippingCarPro) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>CN</Field>
					<Field>
						<xsl:value-of select="RFF/ShippingCarPro" />
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
						<xsl:value-of select="NAD.BY/Name2" />
					</Field>
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
						<Field>XA</Field>
						<Field>
							<xsl:value-of select="NAD.BY/RFF/BuyerBusinessNum" />
						</Field>				
					</Field>	
				</RFF>
			</NAD>
			<NAD> <!-- NAD.ST -->
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.ST/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.ST/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="NAD.ST/Name" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.ST/Name2" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.ST/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.ST/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.ST/Country" />
				</Field>
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
						<Field>XA</Field>
						<Field>
							<xsl:value-of select="NAD.SU/RFF/SupplierBusinessNum" />
						</Field>				
					</Field>	
				</RFF>
				<xsl:if test="string-length(NAD.SU/FII/BankAccountNum) &gt; 0">
				<FII>
					<mapper:incVar name="segmentCount" />
					<Field>SU</Field>
					<Field>
						<Field>
							<xsl:value-of select="NAD.SU/FII/BankAccountNum" />
						</Field>
						<Field>
							<xsl:value-of select="NAD.SU/FII/BankName" />
						</Field>
					</Field>
				</FII>
				</xsl:if>
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
				<Field>
					<Field>
						<xsl:value-of select="PAT/BasedOn" />
					</Field>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="PAT/TermsDesc1" />
					</Field>
					<Field>
						<xsl:value-of select="PAT/TermsDesc2" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>140</Field>
						<Field>
							<xsl:value-of select="PAT/DTM/TermsNetDueDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
				<xsl:if test="string-length(PAT/PCD/InterestCharge) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>2</Field>
						<Field>
							<xsl:value-of select="PAT/PCD/InterestCharge" />
						</Field>
						<Field>13</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(PAT/MOA/InterestAmt) &gt; 0">
				<MOA>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>202</Field>
						<Field>
							<xsl:value-of select="PAT/MOA/InterestAmt" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</PAT>
			<xsl:if test="string-length(ALC/MOA/CustomsDutyCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>
					<Field>ABW</Field>
				</Field>
				<xsl:if test="string-length(ALC/PCD/CustomsDutyChargePercent) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>2</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/CustomsDutyChargePercent" />
						</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(ALC/MOA/CustomsDutyCharge) &gt; 0">
				<MOA>
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/CustomsDutyCharge" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/FreightCharge) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>C</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>
					<Field>FC</Field>
				</Field>
				<xsl:if test="string-length(ALC/PCD/FreightChargePercent) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>2</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/FreightChargePercent" />
						</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(ALC/MOA/FreightCharge) &gt; 0">
				<MOA>
					<Field>
						<Field>23</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/FreightCharge" />
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
				<Field/>
				<Field/>
				<Field/>
				<Field>
					<Field>RAA</Field>
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="ALC/RebateAllowanceDesc" />
					</Field>
				</Field>
				<xsl:if test="string-length(ALC/PCD/RebateAllowancePercent) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>1</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/RebateAllowancePercent" />
						</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(ALC/MOA/RebateAllowance) &gt; 0">
				<MOA>
					<Field>
						<Field>204</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/RebateAllowance" />
						</Field>
					</Field>
				</MOA>
				</xsl:if>
			</ALC>
			</xsl:if>
			<xsl:if test="string-length(ALC/MOA/VolumeDiscount) &gt; 0">
			<ALC>
				<mapper:incVar name="segmentCount" />
				<Field>A</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>
					<Field>VAB</Field>
				</Field>
				<xsl:if test="string-length(ALC/PCD/VolumeDiscountercent) &gt; 0">
				<PCD>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>1</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/VolumeDiscountPercent" />
						</Field>
					</Field>
				</PCD>
				</xsl:if>
				<xsl:if test="string-length(ALC/MOA/VolumeDiscount) &gt; 0">
				<MOA>
					<Field>
						<Field>204</Field>
						<Field>
							<xsl:value-of select="ALC/PCD/VolumeDiscount" />
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
						<xsl:if test="string-length(LIN/PIA/BuyerItemNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>
								5
							</Field>
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
							<Field>
								1
							</Field>
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
						<xsl:if test="string-length(LIN/MEA/ColorCode) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>X5E</Field>
							<Field/>
							<Field>
								<Field>ZZ</Field>
								<Field>
									<xsl:value-of select="LIN/MEA/ColorCode" />
								</Field>
							</Field>
						</MEA>
						</xsl:if>
						<xsl:if test="string-length(LIN/MEA/SizeCode) &gt; 0">
						<MEA>
							<mapper:incVar name="segmentCount" />
							<Field>X6E</Field>
							<Field/>
							<Field>
								<Field>ZZ</Field>
								<Field>
									<xsl:value-of select="LIN/MEA/SizeCode" />
								</Field>
							</Field>
						</MEA>
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
								<Field>128</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/LineItemAmt" />
								</Field>
							</Field>
						</MOA>
						<MOA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>369</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/GSTAmount" />
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
						<xsl:if test="string-length(LIN/RFF/ItemOrderNumber) &gt; 0">
						<RFF>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>ON</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/ItemOrderNumber" />
								</Field>
								<Field>
									<xsl:value-of select="LIN/LineNum" />
								</Field>
							</Field>
						</RFF>
						</xsl:if>
						<TAX>
						<mapper:incVar name="segmentCount" />
							<Field>7</Field>
							<Field>GST</Field>
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
						<xsl:if test="string-length(LIN/ALC/MOA/ItemRebateAllowance) &gt; 0">
						<ALC>
							<mapper:incVar name="segmentCount" />
							<Field>A</Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<Field>VAB</Field>
							</Field>
							<xsl:if test="string-length(LIN/ALC/MOA/ItemRebateAllowancePercent) &gt; 0">
							<PCD>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>1</Field>
									<Field>
										<xsl:value-of select="LIN/ALC/MOA/ItemRebateAllowancePercent" />
									</Field>
								</Field>
							</PCD>
							</xsl:if>
							<xsl:if test="string-length(LIN/ALC/MOA/ItemRebateAllowance) &gt; 0">
							<MOA>
								<mapper:incVar name="segmentCount" />
								<Field>
									<Field>204</Field>
									<Field>
										<xsl:value-of select="LIN/ALC/MOA/ItemRebateAllowance" />
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
						<xsl:value-of select="count(//Item)" />
					</Field>
				</Field>
			</CNT>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>39</Field>
					<Field>
						<xsl:value-of select="MOA/InvoiceTotalAmount" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>128</Field>
					<Field>
						<xsl:value-of select="MOA/Total" />
					</Field>
				</Field>
			</MOA>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>369</Field>
					<Field>
						<xsl:value-of select="MOA/TotalGSTAmount" />
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