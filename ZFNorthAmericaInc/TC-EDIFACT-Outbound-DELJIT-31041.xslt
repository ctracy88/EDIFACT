<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML into a ZF North America DELJIT.
	
	Input: TC XML DELJIT.
	Output: ZF North America EANCOM D97A DELJIT.
	
	Author: Jennifer Ciambro
	Version: 1.0
	Creation Date: April 4, 2017
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
		
		<xsl:variable name="receiverANA" select="/Batch/ASN[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/ASN[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
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
            <!-- Incremental ref for batch -->
            <xsl:variable name="BatchGenNumber">
                <mapper:genNum>
                    <xsl:choose>
                        <xsl:when test="string-length($BatchRefText) &gt; 0">
                            <xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', $BatchRefText, '.', 'ZF NORTH AMERICA', '.', 'DELJIT')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', 'ZF NORTH AMERICA', '.', 'DELJIT')" />
                        </xsl:otherwise>
                    </xsl:choose>
                </mapper:genNum>
            </xsl:variable>          
            <mapper:setVar name="messageCount">0</mapper:setVar>
            <UNB>
                <Field>
                    <Field>UNOA</Field>
                    <Field>1</Field>
                </Field>
                <!-- Sender ANA and Qualifier -->
                <Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <!-- Receiver ANA and Qualifier -->
                <Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field>
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/ReceiverCodeQualifier" />
                    </Field>
                </Field>
                <!-- Date and Time stamps -->
                <Field>
                    <Field>
                        <xsl:value-of select="date:insert('yyMMdd')" />
                    </Field>
                    <Field>
                        <xsl:value-of select="date:insert('hhmm')" />
                    </Field>
                </Field>
                <!-- Interchange Reference Number -->
                <Field>
                    <xsl:value-of select="/Batch/ASN[1]/BatchReferences/BatchRef" />
                </Field>
                <!-- Network Password -->
                <Field>
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <!-- Application Reference -->
                <Field>DELJIT</Field>
                <Field />
                <!-- Processing Priority -->
                <Field />
                <!-- Acknowledgement Request -->
                <Field />
                <!-- Communications Agreement -->
                <Field>
                    <!-- Test Indicator -->
                        <xsl:value-of select="Batch/ASN[1]/BatchReferences/test" />
                </Field>
                <!-- Process each ASN -->
                <xsl:apply-templates select="ASN">
                    <xsl:with-param name="batchRef" select="$BatchGenNumber" />
                </xsl:apply-templates>
				<UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/ASN[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="ASN">
        <xsl:param name="batchRef" />
        <!-- Create a generation number which I'll use in the UNH -->
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
            <!-- Unique sequential number which may be checked -->
            <Field>
                <xsl:value-of select="$MsgRefNum" />
            </Field>
            <Field>
                <Field>
					<xsl:value-of select="UNH/MsgType" />
				</Field>
                <Field>
					<xsl:value-of select="UNH/MsgVersion" />
				</Field>
                <Field>
					<xsl:value-of select="UNH/MsgReleaseNum" />
				</Field>
                <Field>
					<xsl:value-of select="UNH/ControlAgency" />
				</Field>
                <Field>
					
				</Field>
				<Field/>
				<Field/>
                
            </Field>
            <BGM>
                <mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="BGM/DocMsgID" />
					</Field>
					<Field>
						<xsl:value-of select="BGM/DocNum" />
					</Field>
					<Field>
						<xsl:value-of select="BGM/Purpose" />
					</Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="DTM/CreationDate" />
                    </Field>
                    <Field>203</Field>
                </Field>
            </DTM>
			 <FTX>
                <mapper:incVar name="segmentCount" />
                <Field>ADU</Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="FTX/Note" />
				</Field>
            </FTX>
			<NAD> <!-- NAD.SU -->
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field/>
                    <Field>92</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.SU/Name" />
				</Field>
			</NAD>
			<NAD> <!-- NAD.MI -->
                <mapper:incVar name="segmentCount" />
                <Field>MI</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.MI/Code" />
                    </Field>
                    <Field/>
                    <Field>92</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.MI/Name" />
				</Field>
				<CTA>
					<Field>
						<Field>IC</Field>
						<Field>
							<xsl:value-of select="NAD.MI/CTA/InformationContact" />
						</Field>
					</Field>
					<COM>
						<Field>
							<Field>
								<xsl:value-of select="NAD.MI/CTA/COM/Fax" />
							</Field>
							<Field>FX</Field>
						</Field>
					</COM>
					<COM>
						<Field>
							<Field>
								<xsl:value-of select="NAD.MI/CTA/COM/Phone" />
							</Field>
							<Field>TE</Field>
						</Field>
					</COM>
				</CTA>
			</NAD>
			<NAD> <!-- ShipTo -->
                <mapper:incVar name="segmentCount" />
                <Field>ST</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="ShipTo/Code" />
                    </Field>
                    <Field/>
                    <Field>92</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="ShipTo/Name" />
				</Field>
			</NAD>
			<SEQ>
				<Field>
					<xsl:value-of select="SEQ/StatusIndicator" />
				</Field>
				<PAC>
					<Field>
						<xsl:value-of select="SEQ/PAC/NumofPackages" />
					</Field>
					<Field/>
					<Field>
						<xsl:value-of select="SEQ/PAC/TypeOfPackages" />
					</Field>
					<PCI>
						<Field></Field>
						<Field>
							<xsl:value-of select="SEQ/PAC/PCI/ShippingMarks" />
						</Field>
					</PCI>
				</PAC>
			</SEQ>
            <xsl:for-each select="Items">
				<LIN>
					<mapper:incVar name="segmentCount" />
					<Field></Field>
					<Field></Field>
					<Field>
						<Field>
						<xsl:value-of select="LIN/BuyersItemNum" />
						</Field>
						<Field>IN</Field>
					</Field>
					<xsl:if test="string-length(IMD/Description) &gt; 0">
					<IMD>
						<mapper:incVar name="segmentCount" />
						<Field>F</Field>
						<Field/>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="IMD/Description" />
							</Field>
						</Field>
					</IMD>
					</xsl:if>
					<RFF>
						<Field>
							<Field>CW</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/KANBANNum" />
							</Field>
						</Field>
						<DTM>
							<Field>
								<Field>137</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/DTM/DocumentDate" />
								</Field>
								<Field>203</Field>
							</Field>
						</DTM>
					</RFF>
					<RFF>
						<Field>
							<Field>ON</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/OrderNum" />
							</Field>
						</Field>
					</RFF>
					<RFF>
						<Field>
							<Field>SI</Field>
							<Field>
								<xsl:value-of select="LIN/RFF/SIDNumber" />
							</Field>
						</Field>
						<DTM>
							<Field>
								<Field>50</Field>
								<Field>
									<xsl:value-of select="LIN/RFF/DTM/GoodsReceiptDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
					</RFF>
					<LOC>
						<Field>11</Field>
						<Field>
							<xsl:value-of select="LIN/LOC/ReceivingDockNum" />
						</Field>
					</LOC>
					<LOC>
						<Field>159</Field>
						<Field>
							<xsl:value-of select="LIN/LOC/AdditionalInternalDestination" />
						</Field>
					</LOC>
					<QTY>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>1</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/DiscreteQty" />
							</Field>
							<Field>C62</Field>
						</Field>
					</QTY>
					<QTY>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>70</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/CumulativeQtyRec" />
							</Field>
							<Field>C62</Field>
						</Field>
					</QTY>
					<QTY>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>48</Field>
							<Field>
								<xsl:value-of select="LIN/QTY/LastRecQty" />
							</Field>
							<Field>C62</Field>
						</Field>
					</QTY>
					<SCC>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="LIN/QTY/SCC/DeliveryPlanStatusIndicator" />
						</Field>
						<Field></Field>
						<Field>
							<xsl:value-of select="LIN/QTY/SCC/DeliveryPlanStatusFrequency" />
						</Field>
						<DTM>
							<Field>
								<Field>2</Field>
								<Field>
									<xsl:value-of select="LIN/QTY/SCC/DTM/DeliveryDate" />
								</Field>
								<Field>102</Field>
							</Field>
						</DTM>
					</SCC>
				</LIN>	
			</xsl:for-each> <!--End of Item Loop-->
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
    <!--
			Template used to determine if a product is stored in a box or a green tray for ZF North America -->
		
		<xsl:template name="determine-product-case-type"><xsl:param name="name" /></xsl:template></xsl:stylesheet>