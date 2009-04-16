package org.riddl.description;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;

@XmlAccessorType(XmlAccessType.FIELD)
public class Method {

	@XmlAttribute
	protected String in;
	@XmlAttribute
	protected String out;
	@XmlAttribute
	protected String pass;
	@XmlAttribute
	protected String add;
	@XmlAttribute
	protected String remove;

	public Method() {
		super();
	}

	/**
	 * Gets the value of the in property.
	 * 
	 * @return
	 *     possible object is
	 *     {@link String }
	 *     
	 */
	public String getIn() {
	    return in;
	}

	/**
	 * Sets the value of the in property.
	 * 
	 * @param value
	 *     allowed object is
	 *     {@link String }
	 *     
	 */
	public void setIn(String value) {
	    this.in = value;
	}

	/**
	 * Gets the value of the out property.
	 * 
	 * @return
	 *     possible object is
	 *     {@link String }
	 *     
	 */
	public String getOut() {
	    return out;
	}

	/**
	 * Sets the value of the out property.
	 * 
	 * @param value
	 *     allowed object is
	 *     {@link String }
	 *     
	 */
	public void setOut(String value) {
	    this.out = value;
	}

}