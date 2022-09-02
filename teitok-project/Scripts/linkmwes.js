var mtxt = document.getElementById('mtxt');
var linkmwesdata = {};
var seq = []; var selstring = '';

var colorlist = ['#990000', '#009900', '#000099', '#999900', '#990099', '#009999', '#990000', '#009900', '#000099', '#999900', '#990099', '#009999', '#990000', '#009900', '#000099', '#999900', '#990099', '#009999', '#990000', '#009900', '#000099', '#999900', '#990099', '#009999']
var setcolor = [];

var tokinfo = document.getElementById('tokinfo');
if ( !tokinfo ) {
	var tokinfo = document.createElement("div"); 
	tokinfo.setAttribute('id', 'tokinfo');
	document.body.appendChild(tokinfo);
};

if ( jmp ) { 
	var it = document.getElementById(jmp);
	it.style['backgroundColor'] = '#ffffbb'; 
	it.scrollIntoView(true); 
}; // TODO: this should depend on jmp

var linkmwescolor;
for ( var i=0; i<Object.keys(linkmweslist).length; i++) {
	var tmp = Object.keys(linkmweslist)[i];
	var type_val = linkmweslist[tmp]['value'];
	if ( !type_val ) { type_val = tmp; };
	var its = mtxt.querySelectorAll('['+colorattr+'="'+type_val+'"]');
	linkmwescolor = linkmweslist[tmp]['color'];
	if ( !linkmwescolor ) { // Choose a color for this class
		if ( !setcolor[tmp] ) { setcolor[tmp] = colorlist.shift() }; 
		linkmwescolor = setcolor[tmp];
	};
	if ( !linkmwescolor ) { linkmwescolor = 'green'; };
	for ( var a = 0; a<its.length; a++ ) {
		var it = its[a];	
		var itcolor = linkmwescolor;


    if(it.getAttribute(linkto)){
    	it.getAttribute(linkto).split(" ").forEach(function (item) {
    	  var line_from = get_line_point(it);
    	  var line_to = get_line_point(document.getElementById(item));

    	  var line = new LeaderLine(
    		              line_from,
    	                line_to,//LeaderLine.pointAnchor(document.getElementById(item), {x: '50%', y: 10}),
    		               {
    		               	  size: 1.5,
    		               	  endPlug: 'Arrow3',
    		               	  endPlugSize: 1.8,
    		               	  color: 'rgba(226,0,122,0.6)',
    		               	  startSocket: 'top',
    		               	  startSocketGravity: 5,
    		               	  endSocket: 'top',
    		               	  endSocketGravity: 5,
    		               	  path: 'grid',
    		               	});
    	  var representant_to = document.getElementById(item);
    	  assign_line(it,line,'start');
    	  assign_line(representant_to,line,'end');
    	  console.log("line:",it,line_from,line_to);
    	});
    }


		set_elems(it, itcolor);
		/*
		// it.style['font-weight'] = 'bold';
		it.onclick = function(event) {
			doclick(this);
		};
		it.onmouseover = function(event) {
			showinfo(this);
		};
		it.onmouseout = function(event) {
			hideinfo(this);
		};
		*/
		if ( it.getAttribute(linkmweslist[tmp]['linkmwesid']) == hlid ) {
			it.style['backgroundColor'] = '#ffffbb'; 
			if ( !jmp ) { it.scrollIntoView(true); }; // TODO: this should depend on jmp
		}
	};
};



function assign_line(elm,line,position){
	if(!('line' in elm)){
		elm.line = [];
	}
	elm.line.push({ line: line, position: position});
}

function get_line_point ( elm ) {
	if(elm.getAttribute('corresp')){
		var t = elm.getAttribute('corresp')+' ';
		var e = document.getElementById(t.substring(t.indexOf('#')+1, t.indexOf(' ')));
		if(e){
			return e;
		}
	}
	return elm;
}

function set_elems ( elm, itcolor ) {
	if(elm.getAttribute('corresp')){
		elm.getAttribute('corresp').split(" ").forEach(function (item) {
			var e = document.getElementById(item.substring(item.indexOf('#')+1,item.length));
			if(e){
			  set_elem(e, itcolor, elm);
			  var sp = e.nextSibling;
			  if(sp&&sp.nodeName === 'NJS') set_elem(sp, itcolor, elm);
		  }
		});
	}
	set_elem(elm, itcolor, elm);
}

function set_elem (elm, itcolor, main_elem) {
	elm.style.color = itcolor;
	elm.style.borderBottomWidth = '2pt';
	elm.style.borderBottomColor = itcolor;
	elm.style.borderBottomStyle = 'solid';
	elm.onmouseover = function(event) {
			showinfo(main_elem);
	};
	elm.onmouseout = function(event) {
			hideinfo(main_elem);
		};
}


function hideinfo(elm) {
	elm.line.forEach(function (item) {
    item.line.size = 1.5;
    item.line.color = 'rgba(226,0,122,0.6)';
	  if(item.position === 'end') item.line.setOptions({endLabel:''});
    else item.line.setOptions({startLabel: ''});
  });
};

function showinfo(elm) {

	var label = LeaderLine.captionLabel(elm.getAttribute(colorattr),{ color: elm.style.color, outlineColor: 'white'});
	elm.line.forEach(function (item) {
    item.line.size = 2.5;
    item.line.color = elm.style.color;
	  if(item.position === 'end') item.line.setOptions({endLabel:label});
    else item.line.setOptions({startLabel: label});
  });

};
