package org.riddl.generator;

import static org.junit.Assert.*;

import javax.lang.model.element.Modifier;

import org.junit.Test;

public class FieldTest {

	@Test
	public void testSetModifiers() 
	{
		Field testField = new Field();
		testField.setModifiers(Modifier.PRIVATE)
	}

	@Test
	public void testCreateJavaString() {
		fail("Not yet implemented");
	}

}
