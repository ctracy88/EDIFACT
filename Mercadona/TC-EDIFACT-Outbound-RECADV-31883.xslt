<?xml version="1.0" encoding="utf-8"?>
<!--
	XSLT to transform a Generic XML RECADV into a EANCOM D96A Invoice.
	
	Input: Generic XML Recadv.
	Output: EANCOM D96A Recadv.
	
	Author: Charlie Tracy
	Version: 1.0
	Creation Date: 26-Apr-2016
		
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
		
		<xsl:variable name="receiverANA" select="/Batch/Recadv[1]/BatchReferences/ReceiverCode" />
        <!-- Some hubs specify different criterea in test and live modes -->
        <xsl:variable name="testMode" select="/Batch/Recadv[1]/BatchReferences/@test = 'true' or $TestMode = 'true'" />
        <xsl:variable name="vendorID">
            <xsl:choose>
                <xsl:when test="string-length($CustomerCodeForSupplier) &gt; 0">
                    <xsl:value-of select="$CustomerCodeForSupplier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="/Batch/RECADV[1]/Supplier/CustomersCode" />
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
                        <xsl:value-of select="/Batch/Recadv[1]/BatchReferences/SenderCode" />
                    </Field>
                    <Field> <!-- UNB 2.2-->
                        <xsl:value-of select="/Batch/Recadv[1]/BatchReferences/SenderCodeQualifier" />
                    </Field>
                </Field>
                <Field> <!-- UNB 3 -->
                    <Field> <!-- UNB 3.1-->
                        <xsl:value-of select="/Batch/Recadv[1]/BatchReferences/ReceiverCode" />
                    </Field>
                    <Field> <!-- UNB 3.2-->
                        <xsl:value-of select="/Batch/Recadv[1]/BatchReferences/ReceiverCodeQualifier" />
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
                    <xsl:value-of select="/Batch/Recadv[1]/BatchReferences/BatchRef" />
                </Field>
                <Field> <!-- UNB 6 -->
                    <xsl:value-of select="$NetworkPassword" />
                </Field>
                <Field>RECADV</Field> <!-- UNB 7 -->
                <Field /> <!-- UNB 8 -->
                <Field /> <!-- UNB 9 -->
                <Field /> <!-- UNB 10 -->
                <Field> <!-- UNB 11 -->
                        <xsl:value-of select="Batch/Recadv[1]/BatchReferences/test" />
                </Field>
                <xsl:apply-templates select="Recadv">
                    <xsl:with-param name="batchRef"/>
                </xsl:apply-templates>
                <UNZ> 
                    <Field> <!-- UNZ 1 -->
                        <mapper:getVar name="messageCount" />
                    </Field>
                    <Field> <!-- UNZ 2 -->
                        <xsl:value-of select="/Batch/Recadv[1]/BatchReferences/BatchRef" />
                    </Field>
                </UNZ>
            </UNB>
        </Document>
    </xsl:template>
    <xsl:template match="Recadv">
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
                <Field>D</Field>
                <Field>01B</Field>
                <Field>EN</Field>
				<Field>EAN003</Field>
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
                    <Field>9</Field>
					<Field/> <!-- BGM 1.4 -->
				</Field>
                <Field> <!-- BGM 2 -->
                    <xsl:value-of select="BGM/DocNum" />
                </Field>
                <Field>9</Field>
				<Field> <!-- BGM 4 -->
					<xsl:value-of select="BGM/ResponseType" />
				</Field>
            </BGM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>137</Field>
                    <Field>
                        <xsl:value-of select="DTM/ReferenceDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>200</Field>
                    <Field>
						<xsl:value-of select="DTM/DatePickup" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
            <DTM>
                <mapper:incVar name="segmentCount" />
                <Field>
                    <Field>50</Field>
                    <Field>
						<xsl:value-of select="DTM/DeliveryDate" />
                    </Field>
                    <Field>102</Field>
                </Field>
            </DTM>
			<xsl:if test="string-length(RFF/NoteDelivery) &gt; 0">
			<RFF>
				<mapper:incVar name="segmentCount" />
				<Field>
					<Field>DQ</Field>
					<Field>
						<xsl:value-of select="RFF/NoteDelivery" />
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
			</RFF>
			</xsl:if>
			<NAD>
                <mapper:incVar name="segmentCount" />
                <Field>SU</Field>
                <!-- BY = Buyer -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.SU/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.SU/Name" />
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
            </NAD>
            <NAD>
                <mapper:incVar name="segmentCount" />
                <Field>IV</Field>
                <!-- SE = Seller -->
                <Field>
                    <Field>
                        <xsl:value-of select="NAD.IV/Code" />
                    </Field>
                    <Field></Field>
                    <Field>9</Field>
				</Field>
				<Field></Field>
				<Field>
					<xsl:value-of select="NAD.IV/Name" />
				</Field>
				<Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address" />
					</Field>
					<Field>
						<xsl:value-of select="NAD.IV/Address2" />
					</Field>
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/City" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/State" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/ZipCode" />
				</Field>
				<Field>
					<xsl:value-of select="NAD.IV/Country" />
				</Field>
            </NAD>
            <xsl:if test="string-length(TDT/EquipmentNumber) &gt; 0">
			<TDT>
				<mapper:incVar name="segmentCount" />
				<Field>20</Field>
				<Field></Field>
				<Field></Field>
				<Field></Field>
				<Field></Field>
				<Field></Field>
				<Field></Field>
				<Field>
					<Field></Field>
					<Field></Field>
					<Field></Field>
					<Field>
						<xsl:value-of select="TDT/NoteDelivery" />
					</Field>
				</Field>
			</TDT>
			</xsl:if>
			<CPS>
				<mapper:incVar name="segmentCount" />
				<Field>1</Field>
			</CPS>
			<xsl:for-each select="Item">
					<LIN>
						<mapper:incVar name="segmentCount" />
						<Field>
							<xsl:value-of select="Details/LineNum" />
						</Field>
						<Field></Field>
						<Field>
							<Field>
							<xsl:value-of select="Details/EANNum" />
							</Field>
							<xsl:if test="string-length(Details/EANNum) &gt; 0">
							<Field>EN</Field>
							</xsl:if>
						</Field>
						<PIA>
							<mapper:incVar name="segmentCount" />
							<Field>1</Field>
							<Field>
								<Field>
									<xsl:value-of select="Details/BuyersItemNum" />
								</Field>
								<Field>IN</Field>
							</Field>
						</PIA>
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>194</Field>
								<Field>
									<xsl:value-of select="Details/Qty" />
								</Field>
							</Field>
						</QTY>
						<xsl:if test="string-length(Details/CumulativeQty) &gt; 0">
						<QTY>
							<mapper:incVar name="segmentCount" />
							<Field>
								<Field>59</Field>
								<Field>
									<xsl:value-of select="Details/CumulativeQty" />
								</Field>
							</Field>
						</QTY>
						</xsl:if>
						<xsl:if test="string-length(Details/QuantityVariable) &gt; 0">
						<QVR>
							<mapper:incVar name="segmentCount" />
							<Field>
								<xsl:value-of select="Details/QuantityVariable" />
							</Field>
							<Field></Field>
							<Field>
								<xsl:value-of select="Details/QuantityVariableReason" />
							</Field>
						</QVR>
						</xsl:if>
					</LIN>
                </xsl:for-each>
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
 </xsl:stylesheet>