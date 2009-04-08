package com.sun.xjc;

import static org.junit.Assert.*;

import java.io.File;

import org.junit.Test;
import org.xml.sax.SAXParseException;

import com.sun.codemodel.JCodeModel;
import com.sun.tools.xjc.AbortException;
import com.sun.tools.xjc.ErrorReceiver;
import com.sun.tools.xjc.Language;
import com.sun.tools.xjc.ModelLoader;
import com.sun.tools.xjc.Options;
import com.sun.tools.xjc.XJC2Task;
import com.sun.tools.xjc.model.Model;
import com.sun.tools.xjc.outline.Outline;
import com.sun.tools.xjc.util.ErrorReceiverFilter;

public class XJCApiTest {

	@Test
	public void testExecute() 
	{
		Options options = new Options();
		options.addGrammar(new File("myproject/ns/description-1_0.rng"));
		options.setSchemaLanguage(Language.RELAXNG);
		options.debugMode = true;
		options.verbose = true;
		
		//Model xjcModel = new Model(options, new JCodeModel(), 
		ModelLoader.load(options, new JCodeModel(), new ErrorReceiverFilter());

	}

}
