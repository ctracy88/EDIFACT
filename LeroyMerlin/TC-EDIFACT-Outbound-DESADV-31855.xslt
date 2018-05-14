<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML ASN into a specific Cummins EANCOM D96A ASN.
	
	Input: Generic XML Invoice.
	Output: Cummins EANCOM D96A DESADV.
	
	Author: Charlie Tracy
	Version: 1.0
	Creation Date: 28-Apr-2016
	
	Last Modified Date: 28-Apr-2016
	Last Modified By: Charlie Tracy	
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
                    <!-- Number of Documents -->
                    <Field>
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <!-- Interchange Reference Number -->
                    <Field>
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
		<mapper:setVar name="packageIncrementer">0</mapper:setVar>
		<xsl:variable name="currentPackage"></xsl:variable>
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
						<xsl:value-of select="DTM/DatePickup" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
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
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>17</Field>
                    <Field>
						<xsl:value-of select="DTM/EstDeliveryDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
            <xsl:if test="string-length(RFF/BOLNum) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>DQ</Field>
					<Field>
						<xsl:value-of select="RFF/BOLNum" />
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
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>BY</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BY/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
            </NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SH</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SH/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
            </NAD>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
            </NAD>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>DP</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.DP/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
            </NAD>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
            </NAD>
			<xsl:for-each select="Pack">
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
				<PAC>
					<mapper:incVar name="segmentCount" />
					<Field><xsl:value-of select="TotalCartons" /></Field>
					<Field></Field>
					<Field>201</Field>
				</PAC>
				<PAC>
					<mapper:incVar name="segmentCount" />
					<Field><xsl:value-of select="TotalCartons" /></Field>
					<Field></Field>
					<Field>X1</Field>
				</PAC>
				<xsl:for-each select="Item">
					<CPS>
							<mapper:incVar name="segmentCount" />
							<mapper:incVar name="packageIncrementer" />
							<Field>
								<mapper:getVar name="packageIncrementer" />
							</Field>
							<Field>
								<mapper:getVar name="currentPackage" />
							</Field>
					</CPS>
					<PAC>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="Details/CartonNum" />
						</Field>
						<Field>
							<Field>52</Field>
						</Field>
						<Field>PK</Field>
					</PAC>
					<xsl:if test="string-length(Details/ItemLength) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>LN</Field>
						<Field>
							<Field>CMT</Field>
							<Field>
							<xsl:value-of select="Details/ItemLength" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(Details/ItemWidth) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>WD</Field>
						<Field>
							<Field>CMT</Field>
							<Field>
								<xsl:value-of select="Details/ItemWidth" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(Details/ItemHeight) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>HT</Field>
						<Field>
							<Field>CMT</Field>
							<Field>
								<xsl:value-of select="Details/ItemHeight" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<xsl:if test="string-length(Details/ItemWeight) &gt; 0">
					<MEA>
						<mapper:incVar name="segmentCount" />
						<Field>PD</Field>
						<Field>AAB</Field>
						<Field>
							<Field>KGM</Field>
							<Field>
								<xsl:value-of select="Details/ItemWeight" />
							</Field>
						</Field>
					</MEA>
					</xsl:if>
					<PCI>
						<mapper:incVar name="segmentCount" />
						<Field><xsl:value-of select="Details/ISOReg" /></Field>
					</PCI>
					<GIN>
						<mapper:incVar name="segmentCount" />
						<Field>BJ</Field>
						<Field><xsl:value-of select="Details/ShippingContainerCode" /></Field>
					</GIN>
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>1</Field>
						<Field/>
						<Field>
							<Field>
								<xsl:value-of select="Details/EANNum" />
							</Field>
							<Field>EN</Field>
						</Field>
					</LIN>
					<IMD>
						<mapper:incVar name="segmentCount" />
						<Field>C</Field>
						<Field/>
						<Field>
							<Field/>
							<Field/>
							<Field/>
							<Field>
								<xsl:value-of select="Details/Description" />
							</Field>
						</Field>
					</IMD>
					<QTY>
					<mapper:incVar name="segmentCount" />
						<Field>
							<Field>12</Field>
							<Field><xsl:value-of select="Details/Qty" /></Field>
						</Field>
					</QTY>
					<RFF>
						<mapper:incVar name="segmentCount" />
						<Field>
							<Field>ON</Field>
							<Field>
								<xsl:value-of select="Details/ItemVendorNumber" />
							</Field>
						</Field>
					</RFF>
				</xsl:for-each> <!--End of Item Loop-->
			</xsl:for-each> <!--End of Pack Loop-->
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