function WFGraph (xml, container) {
  var xml = xml;
  var container = container;
  var elements = new Array();

  this.generateGraph = function() {
    analyze(xml.documentElement, 0);
    draw();
  }

  var analyze = function(node, line) {
    if(elements[line] == null) elements[line] = new Array();
    var column = elements[line].length;
    var preceding = node;

    for(var i = 0; i < node.childNodes.length; i++) {
      var child = node.childNodesi[i];
      var c_line = 0;
      var c_col = 0;
      if((node.nodeName == "choose") || (node.nodeName == "parallel")) {
        c_line = line+1;
        c_col = elements[line+1].length;
        analyze(child, line+1);
      } else {
        c_line = line +i;
        c_col = elements[line+i].length;
        analyze(child, line+i);
        preceding = child;
      }
      e = new Element(preceding, child, c_line, c_col);
      elements[c_line].push(e);
    }
  }

  var draw = function() {
  }
}

function Element(parent_element, node, line, column) {
  this.parent_element = parent_element;
  this.node = node;
  this.line = line;
  this.column = column;
}
