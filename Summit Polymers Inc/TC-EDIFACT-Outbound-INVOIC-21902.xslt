<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform TC XML INVOIC into a Summit Polymers D97A INVOIC.
	
	Input: TC XML INVOIC
	Output: Summit Polymers D97A INVOIC
	
	Author: Bill Freed
	Version: 1.0
	Creation Date: 11/17/2016
		
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
			<xsl:if test="string-length(DTM/EstimateDeliveryDate) &gt; 0">
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>17</Field>
                    <Field>
						<xsl:value-of select="DTM/EstimatedDeliveryDate" />
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
						<xsl:value-of select="RFF/PONum" />
					</Field>
				</Field>
			</RFF>
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>SI</Field>
					<Field>
						<xsl:value-of select="RFF/ShippersIDforShipment" />
					</Field>
				</Field>
			</RFF>
			<NAD> <!-- NAD.BT -->
                <mapper:incVar name="segmentCount" />
                <Field>BT</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.BT/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.BT/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.BT/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.BT/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.BT/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.BT/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BT/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.BT/ZipCode" />
				</Field>
			</NAD>
            <NAD> <!-- NAD.SF -->
                <mapper:incVar name="segmentCount" />
                <Field>SF</Field>
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SF/Code" />
                    </Field>
                    <Field/>
                    <Field>
						<xsl:value-of select="NAD.SF/CodeType" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<xsl:value-of select="NAD.SF/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.SF/Address1" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.SF/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.SF/ZipCode" />
				</Field>
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
					<xsl:value-of select="NAD.ST/Name" />
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
					<xsl:value-of select="NAD.ST/ZipCode" />
				</Field>
			</NAD>
			<CUX>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>2</Field>
					<Field>
						<xsl:value-of select="CUX/Currency" />
					</Field>
				</Field>
				<DTM>
					<mapper:incVar name="segmentCount" />
					<Field>
						<Field>140</Field>
						<Field>
							<xsl:value-of select="CUX/DTM/PaymentDueDate" />
						</Field>
						<Field>102</Field>
					</Field>
				</DTM>
			</CUX>
			<xsl:if test="string-length(TDT/TransportStageQual) &gt; 0">
			<TDT>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="TDT/TransportStageQual" />
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="TDT/ModeOfTransport" />
					</Field>
				</Field>
				<Field/>
				<Field>
					<Field>
						<xsl:value-of select="TDT/SCAC" />
					</Field>
					<Field/>
					<Field/>
					<Field>
						<xsl:value-of select="TDT/Routing" />
					</Field>
				</Field>
			</TDT>
			</xsl:if>
			<xsl:if test="string-length(PAC/NumOfPackages) &gt; 0">
			<PAC>
				<mapper:incVar name="segmentCount" />
				<Field>
					<xsl:value-of select="PAC/NumOfPackages" />
				</Field>
				<xsl:if test="string-length(PAC/MEA/GrossWeight) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>AAX</Field>
					<Field>
						<Field>G</Field>
					</Field>
					<Field>
						<Field>LBR</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/GrossWeight" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
				<xsl:if test="string-length(PAC/MEA/NetWeight) &gt; 0">
				<MEA>
					<mapper:incVar name="segmentCount" />
					<Field>AAX</Field>
					<Field>
						<Field>N</Field>
					</Field>
					<Field>
						<Field>LBR</Field>
						<Field>
							<xsl:value-of select="PAC/MEA/NetWeight" />
						</Field>
					</Field>
				</MEA>
				</xsl:if>
			</PAC>
			</xsl:if>
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field/>
						<Field/>
						<Field>
							<Field>
								<xsl:value-of select="LIN/BuyersItemNum" />
							</Field>
							<Field>IN</Field>
						</Field>
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
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>12</Field>
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
								<Field>116</Field>
								<Field>
									<xsl:value-of select="LIN/MOA/ItemExtendedNetAmount" />
								</Field>
							</Field>
						</MOA>
						<PRI>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>AAG</Field>
								<Field>
									<xsl:value-of select="LIN/PRI/Price" />
								</Field>
								<Field/>
								<Field/>
								<Field/>
								<Field>
									<xsl:value-of select="LIN/PRI/PriceUOM" />
								</Field>
							</Field>
						</PRI>
					</LIN>
			</xsl:for-each>
			<UNS>
				<mapper:incVar name="segmentCount" />
				<Field>S</Field>
			</UNS>
			<MOA>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>128</Field>
					<Field>
						<xsl:value-of select="MOA/Total" />
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