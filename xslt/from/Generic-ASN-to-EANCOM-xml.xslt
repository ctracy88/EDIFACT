<?xml version="1.0"?>
<!--
	Map to convert a Generic ASN to EANCOM XML DispatchAdvice Message
	
	Author: Roy Hocknull
	Version: 1.0
	Creation Date: 21-Jun-2013
	
	Last Modified Date: 
	Last Modified By: 
-->
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:date="com.css.base.xml.xslt.ext.XsltDateExtension"
                xmlns:str="com.css.base.xml.xslt.ext.XsltStringExtension"
                xmlns:mapper="com.api.tx.MapperEngine"
		xmlns:file="com.css.base.xml.xslt.ext.XsltFileExtension"
                extension-element-prefixes="date mapper str file">
                
    <xsl:output method="xml"/>

	<xsl:param name="Path"/>

	<xsl:template match="/">

		<xsl:variable name="filename">
			<xsl:value-of select="concat(/Batch/ASN/DocumentNumber, '.', position(), '.asn.xml')"/>
		</xsl:variable>

		<!-- This will ensure it is deleted if an error occurs -->
		<mapper:registerCreatedFile>
			<xsl:value-of select="concat($Path, '/', $filename)"/>
		</mapper:registerCreatedFile>

		<file:save name="$filename" path="$Path" append="false" returnData="false" type="xml">

		<xsl:apply-templates select="/Batch/ASN"/>

		</file:save>

	</xsl:template>


	<!-- Process an ASN -->
	<xsl:template match="ASN">

		<sh:StandardBusinessDocument xmlns:sh="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader" xmlns:deliver="urn:ean.ucc:deliver:2" xmlns:eanucc="urn:ean.ucc:2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.unece.org/cefact/namespaces/StandardBusinessDocumentHeader ../Schemas/sbdh/StandardBusinessDocumentHeader.xsd urn:ean.ucc:2 ../Schemas/OrderResponseProxy.xsd">
			<sh:StandardBusinessDocumentHeader>
				<sh:HeaderVersion>2.2</sh:HeaderVersion>
					<sh:Sender>
						<sh:Identifier Authority="EAN.UCC"><xsl:value-of select="BatchReferences/SenderCode"/></sh:Identifier>
					</sh:Sender>
					<sh:Receiver>
						<sh:Identifier Authority="EAN.UCC"><xsl:value-of select="BatchReferences/ReceiverCode"/></sh:Identifier>
					</sh:Receiver>
					<sh:DocumentIdentification>
						<sh:Standard>EAN.UCC</sh:Standard>
						<sh:TypeVersion>2.0.2</sh:TypeVersion>
						<sh:InstanceIdentifier><xsl:value-of select="DocumentNumber"/></sh:InstanceIdentifier>
						<sh:Type>DispatchAdvice</sh:Type>
						<sh:MultipleType>false</sh:MultipleType>
						<sh:CreationDateAndTime><xsl:value-of select="concat(date:insert('yyyy-MM-dd'), 'T', date:insert('HH:mm:ss.SSS'))"/></sh:CreationDateAndTime>
					</sh:DocumentIdentification>
			</sh:StandardBusinessDocumentHeader>

			<eanucc:message>
				<entityIdentification>
					<uniqueCreatorIdentification><xsl:value-of select="DocumentNumber"/></uniqueCreatorIdentification>
					<contentOwner>
						<gln><xsl:value-of select="Supplier/EanCode"/></gln>
					</contentOwner>
				</entityIdentification>
				<eanucc:transaction>
					<entityIdentification>
						<uniqueCreatorIdentification/>
						<contentOwner>
							<gln><xsl:value-of select="Supplier/EanCode"/></gln>
						</contentOwner>
					</entityIdentification>
					<command>
						<eanucc:documentCommand>
							<documentCommandHeader type="ADD">
								<entityIdentification>
									<uniqueCreatorIdentification><xsl:value-of select="DocumentNumber"/></uniqueCreatorIdentification>
									<contentOwner>
										<gln><xsl:value-of select="Supplier/EanCode"/></gln>
									</contentOwner>
								</entityIdentification>
							</documentCommandHeader>

							<documentCommandOperand xmlns:deliver="urn:ean.ucc:deliver:2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
								<deliver:despatchAdvice documentStatus="ORIGINAL" xsi:schemaLocation="urn:ean.ucc:2 ../Schemas/DespatchAdviceProxy.xsd">

									<xsl:attribute name="creationDateTime">
										<xsl:value-of select="concat(date:insert('yyyy-MM-dd'), 'T', date:insert('HH:mm:ss.SSS'))"/>
									</xsl:attribute>

									<contentVersion>
										<versionIdentification>2.0.2</versionIdentification>
									</contentVersion>
									<documentStructureVersion>
										<versionIdentification>2.0.2</versionIdentification>
									</documentStructureVersion>

									<estimatedDelivery>
										<estimatedDeliveryDateTime>
											<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyy-MM-dd'T'HH:mm:ss">
												<xsl:value-of select="DeliveryDate"/>
											</date:reformat>
										</estimatedDeliveryDateTime>
									</estimatedDelivery>

								<!--	No Carrier Details supplied
									<carrier>
										<gln><xsl:value-of select=""/></gln>
									</carrier>-->

								<!--	No Shipper details supplied
									<shipper>
										<gln></gln>
									</shipper>-->

									<shipFrom>
										<gln><xsl:value-of select="Consignor/EanCode"/></gln>
									</shipFrom>

									<shipTo>
										<gln><xsl:value-of select="DeliverTo/EanCode"/></gln>
										<additionalPartyIdentification>
											<additionalPartyIdentificationValue><xsl:value-of select="DeliverTo/CustomersCode"/></additionalPartyIdentificationValue>
											<additionalPartyIdentificationType>SELLER_ASSIGNED_IDENTIFIER_FOR_A_PARTY</additionalPartyIdentificationType>
										</additionalPartyIdentification>
										<additionalPartyIdentification>
											<additionalPartyIdentificationValue><xsl:value-of select="DeliverTo/SuppliersCode"/></additionalPartyIdentificationValue>
											<additionalPartyIdentificationType>BUYER_ASSIGNED_IDENTIFIER_FOR_A_PARTY</additionalPartyIdentificationType>
										</additionalPartyIdentification>
									</shipTo>

									<receiver>
										<gln><xsl:value-of select="Consignee/EanCode"/></gln>
										<additionalPartyIdentification>
											<additionalPartyIdentificationValue><xsl:value-of select="Consignee/SuppliersCode"/></additionalPartyIdentificationValue>
											<additionalPartyIdentificationType>SELLER_ASSIGNED_IDENTIFIER_FOR_A_PARTY</additionalPartyIdentificationType>
										</additionalPartyIdentification>
										<additionalPartyIdentification>
											<additionalPartyIdentificationValue><xsl:value-of select="Consignee/CustomersCode"/></additionalPartyIdentificationValue>
											<additionalPartyIdentificationType>BUYER_ASSIGNED_IDENTIFIER_FOR_A_PARTY</additionalPartyIdentificationType>
										</additionalPartyIdentification>
									</receiver>

									<despatchAdviceIdentification>
										<uniqueCreatorIdentification><xsl:value-of select="DeliveryNoteNumber"/></uniqueCreatorIdentification>
										<contentOwner>
											<gln><xsl:value-of select="Supplier/EanCode"/></gln>
										</contentOwner>
									</despatchAdviceIdentification>

									<deliveryNote>
										<referenceDateTime>2013-01-31T00:00:00
                                                                                        <date:reformat curFormat="yyyy-MM-dd" newFormat="yyyy-MM-dd'T'HH:mm:ss">
                                                                                                <xsl:value-of select="DeliveryNoteDate"/>
                                                                                        </date:reformat>
										</referenceDateTime>
										<referenceIdentification><xsl:value-of select="DeliveryNoteNumber"/></referenceIdentification>
									</deliveryNote>

									<orderIdentification>
										<referenceDateTime>
                                                                                      <date:reformat curFormat="yyyy-MM-dd" newFormat="yyyy-MM-dd'T'HH:mm:ss">
                                                                                                <xsl:value-of select="OrderDate/Customers"/>
                                                                                        </date:reformat>
										</referenceDateTime>
										<referenceIdentification><xsl:value-of select="OrderNumber/Customers"/></referenceIdentification>
									</orderIdentification>

									<xsl:apply-templates select="Package/Product"/>

								</deliver:despatchAdvice>

							</documentCommandOperand>

						</eanucc:documentCommand>	

					</command>

				</eanucc:transaction>

			</eanucc:message>

		</sh:StandardBusinessDocument>

	</xsl:template> <!-- ASN -->

	<xsl:template match="Product">

		<despatchItem>

			<xsl:attribute name="number">
				<xsl:value-of select="LineNumber"/>
			</xsl:attribute>

			<tradeItemUnit>
				<itemContained>
					<quantityContained>
						<measurementValue>

							<xsl:attribute name="unitOfMeasure">
								<xsl:value-of select="Quantity/AmountPerUnit"/>
							</xsl:attribute>

							<value><xsl:value-of select="Quantity/Amount"/></value>
						</measurementValue>
					</quantityContained>

					<containedItemIdentification>
						<gtin><xsl:value-of select="EanCode"/></gtin>
						<additionalTradeItemIdentification>
							<additionalTradeItemIdentificationValue><xsl:value-of select="SuppliersCode"/></additionalTradeItemIdentificationValue>
							<additionalTradeItemIdentificationType>SUPPLIER_ASSIGNED</additionalTradeItemIdentificationType>
						</additionalTradeItemIdentification>
						<additionalTradeItemIdentification>
							<additionalTradeItemIdentificationValue><xsl:value-of select="CustomersCode"/></additionalTradeItemIdentificationValue>
							<additionalTradeItemIdentificationType>BUYER_ASSIGNED</additionalTradeItemIdentificationType>
						</additionalTradeItemIdentification>
					</containedItemIdentification>
					<orderIdentification>

						<xsl:attribute name="number">
							<xsl:value-of select="OrderLineNumber"/>
						</xsl:attribute>

						<reference>
							<referenceDateTime>
								<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyy-MM-dd'T'HH:mm:ss">
									<xsl:value-of select="OrderDate/Customers"/>
								</date:reformat>
							</referenceDateTime>
							<referenceIdentification><xsl:value-of select="OrderNumber/Customers"/></referenceIdentification>
						</reference>

					</orderIdentification>

					<deliveryNote>

						<xsl:attribute name="number">
							<xsl:value-of select="LineNumber"/>
						</xsl:attribute>

						<reference>
							<referenceDateTime>
								<date:reformat curFormat="yyyy-MM-dd" newFormat="yyyy-MM-dd'T'HH:mm:ss">
									<xsl:value-of select="DeliveryNoteDate"/>
								</date:reformat>
							</referenceDateTime>
							<referenceIdentification><xsl:value-of select="DeliveryNoteNumber"/></referenceIdentification>
						</reference>
					</deliveryNote>
				</itemContained>
			</tradeItemUnit>
		</despatchItem>

	</xsl:template> <!-- Package -->

</xsl:stylesheet>
