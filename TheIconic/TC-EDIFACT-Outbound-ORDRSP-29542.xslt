<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a TC XML ORDRSP into The Iconic D01B ORDRSP.
	
	Input: TC XML ORDRSP.
	Output: The Inconic EDIFACT D01B ORDRSP.
	
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
		
		<xsl:variable name="receiverANA" select="/Batch/Ordrsp[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/Ordrsp[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/Ordrsp[1]/Supplier/CustomersCode" />
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
                        <xsl:value-of select="/Batch/Ordrsp[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field> <!-- UNB 2.2-->
                        <xsl:value-of select="/Batch/Ordrsp[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/Ordrsp[1]/BatchReferences/ReceiverCode" />
                    </Field>
					<!-- UNB 3.2-->
					<xsl:choose>
						<xsl:when test="Batch/Ordrsp[1]/BatchReferences/TestProdFlag='1'">
							<Field>ZZZ</Field> 
						</xsl:when>
						<xsl:otherwise>
							<Field>
								<xsl:value-of select="/Batch/Ordrsp[1]/BatchReferences/ReceiverCodeQualifier" />
							</Field>							
						</xsl:otherwise>
					</xsl:choose>
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
                    <xsl:value-of select="/Batch/Ordrsp[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field></Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field>1</Field>
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="Batch/Ordrsp[1]/BatchReferences/TestProdFlag" />
                </Field>
                <xsl:apply-templates select="Ordrsp">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/Ordrsp[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="Ordrsp">
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
				<Field>EAN007</Field>
			</Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
                <Field> <!-- BGM 1 -->
                    <Field> <!-- BGM 1.1 -->
						<xsl:value-of select="BGM/DocMsgCode" />
					</Field>
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
                        <xsl:value-of select="DTM/PODate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<xsl:if test="string-length(DTM/DateRequestedDelivery) &gt; 0">
			<DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>2</Field>
                    <Field>
                        <xsl:value-of select="DTM/DateRequestedDelivery" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			</xsl:if>
			<xsl:if test="string-length(FTX/TermsOfPayment) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAB</Field>
				<Field/>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/TermsOfPayment" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<xsl:if test="string-length(FTX/RejectionNote) &gt; 0">
			<FTX>
				<mapper:incVar name="segmentCount" />
				<Field>AAI</Field>
				<Field/>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="FTX/RejectionNote" />
					</Field>
				</Field>
			</FTX>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="RFF/OrderNumber" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>171</Field>
						<Field>
							<xsl:value-of select="RFF/DTM/OrderDate" />
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
						<xsl:value-of select="BuyingParty/Code" />
                    </Field>
                    <Field></Field>
                    <Field>
						<xsl:value-of select="BuyingParty/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="BuyingParty/Name" />
					</Field>
					<Field>
						<xsl:value-of select="BuyingParty/Name2" />
					</Field>
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="BuyingParty/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="BuyingParty/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="BuyingParty/City" />
				</Field>
				<Field>
					<xsl:value-of select="BuyingParty/State" />
				</Field>
				<Field>
					<xsl:value-of select="BuyingParty/Zip" />
				</Field>
				<Field>
					<xsl:value-of select="BuyingParty/Country" />
				</Field>
            </NAD>
			<NAD> <!-- NAD.ST -->
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
				<Field>
                    <Field>
						<xsl:value-of select="NAD.ST/Code" />
                    </Field>
                    <Field></Field>
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
						<xsl:value-of select="NAD.ST/Address1" />
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
					<xsl:value-of select="NAD.ST/Zip" />
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
                    <Field></Field>
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
					<xsl:value-of select="NAD.SU/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SU/Country" />
				</Field>
            </NAD>
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>
						<xsl:value-of select="CUX/CurrencyUsage" />
					</Field>
					<Field>
						<xsl:value-of select="CUX/Currency" />
					</Field>
					<Field>
						<xsl:value-of select="CUX/CurrencyType" />
					</Field>
				</Field>
			</CUX>
			<xsl:if test="string-length(TOD/DeliveryTransportTermsDesc) &gt; 0">
			<TOD>
				<mapper:incVar name="segmentCount" />
				<Field>5</Field>
				<Field/>
				<Field>
					<Field/>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="TOD/DeliveryTransportTermsDesc" />
					</Field>
				</Field>
			</TOD>
			</xsl:if>
			<xsl:if test="(BGM/MsgFunction) &lt;= 4">
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/LineNum" />
						</Field>
						<Field>
							<xsl:value-of select="LIN/Status" />
						</Field>
						<Field>
							<Field>
								<xsl:value-of select="LIN/GTINUPCNum" />
							</Field>
							<Field>SRV</Field>
						</Field>
						<xsl:if test="string-length(LIN/PIA/BuyersItemNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/PIA/ProductIDType" />
							</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/BuyersItemNum" />
								</Field>
								<Field>IN</Field>							
							</Field>				
						</PIA>
						</xsl:if>
						<xsl:if test="string-length(LIN/PIA/SuppliersArticleNum) &gt; 0">
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="LIN/PIA/ProductIDType" />
							</Field>
							<Field>
								<Field>
									<xsl:value-of select="LIN/PIA/SuppliersArticleNum" />
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
									<xsl:value-of select="LIN/IMD/Description" />
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
						<xsl:if test="string-length(LIN/QTY/QtyOrdered) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>21</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/QtyOrdered" />
								</Field>
								<Field>EA</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/QTY/QtyBackorder) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>83</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/QtyBackorder" />
								</Field>
								<Field>EA</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/QTY/QtyDelivered) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>113</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/QtyDelivered" />
								</Field>
								<Field>EA</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(LIN/DTM/ScheduledDeliveryDate) &gt; 0">
						<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>359</Field>
								<Field>
									<xsl:value-of select="LIN/DTM/ScheduledDeliveryDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
						</xsl:if>
						<xsl:if test="string-length(LIN/DTM/BackorderDate) &gt; 0">
						<DTM>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>506</Field>
								<Field>
									<xsl:value-of select="LIN/DTM/BackorderDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
						</xsl:if>
						<xsl:if test="string-length(LIN/FTX/ItemNote) &gt; 0">
						<FTX>
							<mapper:incVar name="segmentCount" />
							<Field>LIN</Field>
							<Field/>
							<Field/>
							<Field>
								<Field>
									<xsl:value-of select="LIN/FTX/ItemNote" />
								</Field>
							</Field>
						</FTX>
						</xsl:if>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAB</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/ItemUnitPrice" />
								</Field>
							</Field>
						</PRI>
						<TAX>
						<mapper:incVar name="segmentCount" />
							<Field>7</Field>
							<Field>GST</Field>
							<Field/>
							<Field/>
							<Field>
								<Field></Field>
								<Field></Field>
								<Field></Field>
								<Field>
									<xsl:value-of select="LIN/TAX/GSTTax" />
								</Field>
							</Field>
						</TAX>
					</LIN>
                </xsl:for-each>
				</xsl:if>
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>
			<CNT>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>
						<xsl:value-of select="count(//Item)" />
					</Field>
					<Field>
						<xsl:value-of select="count(//Item)" />
					</Field>
				</Field>
			</CNT>
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