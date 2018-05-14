<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML ASN into a Boughey Distribution EANCOM D96A ASN.
	
	Input: TC XML DESADV.
	Output: Boughey Distribution EANCOM D96A DESADV.
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: September 14, 2016
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
                            <xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', $BatchRefText, '.', 'TESCO', '.', 'DESADV')" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(/Batch/ASN[1]/BatchReferences/SenderCode, '.', 'TESCO', '.', 'DESADV')" />
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
                <Field>DESADV</Field>
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
					<Field>351</Field>
					<Field>
						<xsl:value-of select="BGM/DocNum" />
					</Field>
					<Field>9</Field>
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
			<xsl:if test="string-length(DTM/ShipmentDate) &gt; 0">
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>11</Field>
                    <Field>
                        <xsl:value-of select="DTM/ShipmentDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			</xsl:if>
			<xsl:if test="string-length(DTM/DeliveryDate) &gt; 0">
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>2</Field>
                    <Field>
						<xsl:value-of select="DTM/DeliveryDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			</xsl:if>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>ON</Field>
					<Field>
						<xsl:value-of select="RFF/DepositorOrderNum" />
					</Field>
				</Field>
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
			<NAD><!-- BY = Buyer -->
				<mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
					<Field/>
					<Field>9</Field>
                </Field>
				<CTA>
					<mapper:incVar name="segmentCount" />
					<Field>OC</Field>
					<Field>
						<Field/>
						<Field>
							<xsl:value-of select="NAD.BY/CTA/Name" />
						</Field>
					</Field>
				</CTA>
			</NAD>
			<NAD><!-- SU = Supplier -->
				<mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
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
                        <xsl:value-of select="NAD.ST/Code" />
                    </Field>
                </Field>
			</NAD>
			<xsl:if test="string-length(RFF/PromotionNum) &gt; 0">
			<NAD> <!-- DP = Delivery Party -->
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.CZ/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.CZ/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.CZ/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.CZ/Address1" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.CZ/City" />
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.CZ/Zip" />
				</Field>
			</NAD>
			</xsl:if>
            <xsl:for-each select="ItemsNoPack">
				<CPS>
					<mapper:incVar name="segmentCount" />
					<mapper:incVar name="packageIncrementer" />
					<mapper:setVar name="currentPackage">
						<mapper:getVar name="packageIncrementer" />
					</mapper:setVar>
					<Field>
						<mapper:getVar name="packageIncrementer" />
					</Field>
				</CPS>
				<LIN>
					<mapper:incVar name="segmentCount" />
					<Field>
						<xsl:value-of select="LineNumber" />
					</Field>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="EANNum" />
						</Field>
						<Field>EN</Field>
					</Field>
				</LIN>
				<xsl:if test="string-length(BuyerItemNum) &gt; 0">
				<PIA>
					<mapper:incVar name="segmentCount" />
					<Field>1</Field>
					<Field>
						<Field>
							<xsl:value-of select="BuyerItemNum" />
						</Field>
						<Field>IN</Field>
					</Field>
				</PIA>
				</xsl:if>
				<xsl:if test="string-length(ItemModelNumber) &gt; 0">
				<PIA>
					<mapper:incVar name="segmentCount" />
					<Field>1</Field>
					<Field>
						<Field>
							<xsl:value-of select="ItemModelNumber" />
						</Field>
						<Field>SA</Field>
					</Field>
				</PIA>
				</xsl:if>
				<xsl:if test="string-length(PromotionNum) &gt; 0">
				<PIA>
					<mapper:incVar name="segmentCount" />
					<Field>1</Field>
					<Field>
						<Field>
							<xsl:value-of select="PromotionNum" />
						</Field>
						<Field>GN</Field>
					</Field>
				</PIA>
				</xsl:if>
				<xsl:if test="string-length(BatchNum) &gt; 0">
				<PIA>
					<mapper:incVar name="segmentCount" />
					<Field>1</Field>
					<Field>
						<Field>
							<xsl:value-of select="BatchNum" />
						</Field>
						<Field>NB</Field>
					</Field>
				</PIA>
				</xsl:if>
				<xsl:if test="string-length(Description) &gt; 0">
				<IMD>
					<mapper:incVar name="segmentCount" />
					<Field>F</Field>
					<Field/>
					<Field>
						<Field/>
						<Field/>
						<Field/>
						<Field>
							<xsl:value-of select="Description" />
						</Field>
					</Field>
				</IMD>
				</xsl:if>
				<xsl:if test="string-length(Qty) &gt; 0">
				<QTY>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>12</Field>
						<Field>
							<xsl:value-of select="Qty" />
						</Field>
					</Field>
				</QTY>
				</xsl:if>
				<xsl:if test="string-length(ExpDate) &gt; 0">
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>36</Field>
						<Field>
							<xsl:value-of select="ExpDate" />
						</Field>
					</Field>
				</DTM>
				</xsl:if>
				<xsl:if test="string-length(ExpDate) &gt; 0">
				<FTX>
					<mapper:incVar name="segmentCount" />
					<Field>ZZZ</Field>
					<Field>1</Field>
					<Field/>
					<Field>
						<Field>
							<xsl:value-of select="ItemNote" />
						</Field>
					</Field>
				</FTX>
				</xsl:if>
			</xsl:for-each> <!--End of ItemsNoPack Loop-->
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
			Template used to determine if a product is stored in a box or a green tray for Tesco -->
		
		<xsl:template name="determine-product-case-type"><xsl:param name="name" /></xsl:template></xsl:stylesheet>