//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, vJAXB 2.1.3 in JDK 1.6 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2009.03.23 at 11:25:22 AM MEZ 
//


package org.relaxng.structure;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyAttribute;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlElementRef;
import javax.xml.bind.annotation.XmlElementRefs;
import javax.xml.bind.annotation.XmlRootElement;
import javax.xml.bind.annotation.XmlSchemaType;
import javax.xml.bind.annotation.XmlType;
import javax.xml.namespace.QName;
import org.w3c.dom.Element;


/**
 * <p>Java class for anonymous complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType>
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;group ref="{http://relaxng.org/ns/structure/1.0}open-patterns"/>
 *       &lt;attGroup ref="{http://relaxng.org/ns/structure/1.0}common-atts"/>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "", propOrder = {
    "anyOrAnyOrGroup"
})
@XmlRootElement(name = "group")
public class Group {

    @XmlElementRefs({
        @XmlElementRef(name = "oneOrMore", namespace = "http://relaxng.org/ns/structure/1.0", type = OneOrMore.class),
        @XmlElementRef(name = "mixed", namespace = "http://relaxng.org/ns/structure/1.0", type = Mixed.class),
        @XmlElementRef(name = "text", namespace = "http://relaxng.org/ns/structure/1.0", type = Text.class),
        @XmlElementRef(name = "list", namespace = "http://relaxng.org/ns/structure/1.0", type = org.relaxng.structure.List.class),
        @XmlElementRef(name = "interleave", namespace = "http://relaxng.org/ns/structure/1.0", type = Interleave.class),
        @XmlElementRef(name = "optional", namespace = "http://relaxng.org/ns/structure/1.0", type = Optional.class),
        @XmlElementRef(name = "empty", namespace = "http://relaxng.org/ns/structure/1.0", type = Empty.class),
        @XmlElementRef(name = "value", namespace = "http://relaxng.org/ns/structure/1.0", type = Value.class),
        @XmlElementRef(name = "parentRef", namespace = "http://relaxng.org/ns/structure/1.0", type = ParentRef.class),
        @XmlElementRef(name = "notAllowed", namespace = "http://relaxng.org/ns/structure/1.0", type = NotAllowed.class),
        @XmlElementRef(name = "grammar", namespace = "http://relaxng.org/ns/structure/1.0", type = Grammar.class),
        @XmlElementRef(name = "ref", namespace = "http://relaxng.org/ns/structure/1.0", type = Ref.class),
        @XmlElementRef(name = "data", namespace = "http://relaxng.org/ns/structure/1.0", type = JAXBElement.class),
        @XmlElementRef(name = "group", namespace = "http://relaxng.org/ns/structure/1.0", type = Group.class),
        @XmlElementRef(name = "zeroOrMore", namespace = "http://relaxng.org/ns/structure/1.0", type = ZeroOrMore.class),
        @XmlElementRef(name = "choice", namespace = "http://relaxng.org/ns/structure/1.0", type = JAXBElement.class),
        @XmlElementRef(name = "externalRef", namespace = "http://relaxng.org/ns/structure/1.0", type = ExternalRef.class)
    })
    @XmlAnyElement
    protected java.util.List<Object> anyOrAnyOrGroup;
    @XmlAttribute
    @XmlSchemaType(name = "anySimpleType")
    protected String ns;
    @XmlAttribute
    @XmlSchemaType(name = "anyURI")
    protected String datatypeLibrary;
    @XmlAnyAttribute
    private Map<QName, String> otherAttributes = new HashMap<QName, String>();

    /**
     * Gets the value of the anyOrAnyOrGroup property.
     * 
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the anyOrAnyOrGroup property.
     * 
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getAnyOrAnyOrGroup().add(newItem);
     * </pre>
     * 
     * 
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link OneOrMore }
     * {@link Text }
     * {@link Mixed }
     * {@link org.relaxng.structure.List }
     * {@link Element }
     * {@link Interleave }
     * {@link Optional }
     * {@link Empty }
     * {@link NotAllowed }
     * {@link ParentRef }
     * {@link Value }
     * {@link Ref }
     * {@link Grammar }
     * {@link Group }
     * {@link JAXBElement }{@code <}{@link Data }{@code >}
     * {@link ZeroOrMore }
     * {@link JAXBElement }{@code <}{@link Interleave.Choice }{@code >}
     * {@link ExternalRef }
     * 
     * 
     */
    public java.util.List<Object> getAnyOrAnyOrGroup() {
        if (anyOrAnyOrGroup == null) {
            anyOrAnyOrGroup = new ArrayList<Object>();
        }
        return this.anyOrAnyOrGroup;
    }

    /**
     * Gets the value of the ns property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getNs() {
        return ns;
    }

    /**
     * Sets the value of the ns property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setNs(String value) {
        this.ns = value;
    }

    /**
     * Gets the value of the datatypeLibrary property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getDatatypeLibrary() {
        return datatypeLibrary;
    }

    /**
     * Sets the value of the datatypeLibrary property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setDatatypeLibrary(String value) {
        this.datatypeLibrary = value;
    }

    /**
     * Gets a map that contains attributes that aren't bound to any typed property on this class.
     * 
     * <p>
     * the map is keyed by the name of the attribute and 
     * the value is the string value of the attribute.
     * 
     * the map returned by this method is live, and you can add new attribute
     * by updating the map directly. Because of this design, there's no setter.
     * 
     * 
     * @return
     *     always non-null
     */
    public Map<QName, String> getOtherAttributes() {
        return otherAttributes;
    }

}
