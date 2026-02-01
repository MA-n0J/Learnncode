console.log("Initializing Blockly for Python...");

// Global variables to cache the workspace and its state
let cachedWorkspace = null;
let cachedWorkspaceXml = null;
let isBlocklyLoaded = false;

function defineCustomBlocks() {
  console.log("Defining all blocks");

  // Control Blocks
  Blockly.Blocks['controls_if'] = {
    init: function() {
      this.appendValueInput('IF0')
          .setCheck('Boolean')
          .appendField(new Blockly.FieldLabel('if'));
      this.appendStatementInput('DO0')
          .appendField('');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
      this.setTooltip('If condition');
    }
  };

  Blockly.Blocks['controls_if_else'] = {
    init: function() {
      this.appendValueInput('IF0')
          .setCheck('Boolean')
          .appendField(new Blockly.FieldLabel('if'));
      this.appendStatementInput('DO0')
          .appendField('');
      this.appendStatementInput('ELSE')
          .appendField('else');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
      this.setTooltip('If-else condition');
    }
  };

  Blockly.Blocks['controls_ifelseif'] = {
    init: function() {
      this.appendValueInput('IF0')
          .setCheck('Boolean')
          .appendField(new Blockly.FieldLabel('if'));
      this.appendStatementInput('DO0')
          .appendField('');
      this.appendValueInput('IF1')
          .setCheck('Boolean')
          .appendField('elif');
      this.appendStatementInput('DO1')
          .appendField('');
      this.appendStatementInput('ELSE')
          .appendField('else');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
      this.setTooltip('If-elseif-else condition');
    }
  };

  Blockly.Blocks['controls_for'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldLabel('for'))
          .appendField(new Blockly.FieldVariable('i'), 'VAR');
      this.appendValueInput('FROM')
          .setCheck('Number')
          .appendField('from');
      this.appendValueInput('TO')
          .setCheck('Number')
          .appendField('to');
      this.appendStatementInput('DO')
          .appendField('');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
      this.setTooltip('For loop with range');
    }
  };

  Blockly.Blocks['controls_whileUntil'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldLabel('while'));
      this.appendValueInput('BOOL')
          .setCheck('Boolean')
          .appendField('');
      this.appendStatementInput('DO')
          .appendField('');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
      this.setTooltip('While loop');
    }
  };

  Blockly.Blocks['import_statement'] = {
    init: function() {
      this.appendDummyInput()
          .appendField('import')
          .appendField(new Blockly.FieldTextInput('module'), 'MODULE');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(120);
      this.setTooltip('Import a Python module');
    }
  };

  // Logic Blocks (Redesigned to have a trapezoid-like shape)
  Blockly.Blocks['logic_compare'] = {
    init: function() {
      this.appendDummyInput()
          .appendField('<');
      this.appendValueInput('A')
          .setCheck(null);
      this.appendDummyInput()
          .appendField(new Blockly.FieldDropdown([
            ['==', 'EQ'], ['!=', 'NEQ'], ['<', 'LT'],
            ['<=', 'LTE'], ['>', 'GT'], ['>=', 'GTE']
          ]), 'OP');
      this.appendValueInput('B')
          .setCheck(null);
      this.appendDummyInput()
          .appendField('>');
      this.setOutput(true, 'Boolean');
      this.setColour(210);
      this.setTooltip('Compare two values');
      this.setOutputShape(Blockly.OUTPUT_SHAPE_HEXAGONAL);
    }
  };

  Blockly.Blocks['logic_operation'] = {
    init: function() {
      this.appendDummyInput()
          .appendField('<');
      this.appendValueInput('A')
          .setCheck('Boolean');
      this.appendDummyInput()
          .appendField(new Blockly.FieldDropdown([['and', 'AND'], ['or', 'OR']]), 'OP');
      this.appendValueInput('B')
          .setCheck('Boolean');
      this.appendDummyInput()
          .appendField('>');
      this.setOutput(true, 'Boolean');
      this.setColour(210);
      this.setTooltip('Logical operation');
      this.setOutputShape(Blockly.OUTPUT_SHAPE_HEXAGONAL);
    }
  };

  Blockly.Blocks['logic_boolean'] = {
    init: function() {
      this.appendDummyInput()
          .appendField('<')
          .appendField(new Blockly.FieldDropdown([['true', 'TRUE'], ['false', 'FALSE']]), 'BOOL')
          .appendField('>');
      this.setOutput(true, 'Boolean');
      this.setColour(210);
      this.setTooltip('Boolean value');
      this.setOutputShape(Blockly.OUTPUT_SHAPE_HEXAGONAL);
    }
  };

  // Math Blocks
  Blockly.Blocks['math_number'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldNumber(0), 'NUM');
      this.setOutput(true, 'Number');
      this.setColour(230);
      this.setTooltip('A number');
    }
  };

  Blockly.Blocks['math_arithmetic'] = {
    init: function() {
      this.appendValueInput('A')
          .setCheck('Number');
      this.appendValueInput('B')
          .setCheck('Number')
          .appendField(new Blockly.FieldDropdown([
            ['+', 'ADD'], ['-', 'MINUS'], ['*', 'MULTIPLY'], ['/', 'DIVIDE']
          ]), 'OP');
      this.setOutput(true, 'Number');
      this.setColour(230);
      this.setTooltip('Arithmetic operation');
    }
  };

  Blockly.Blocks['math_round'] = {
    init: function() {
      this.appendValueInput('VALUE')
          .setCheck('Number')
          .appendField('round');
      this.setOutput(true, 'Number');
      this.setColour(230);
      this.setTooltip('Round a number');
    }
  };

  // Text Blocks
  Blockly.Blocks['text'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldTextInput(''), 'TEXT');
      this.setOutput(true, 'String');
      this.setColour(160);
      this.setTooltip('Text value');
    }
  };

  Blockly.Blocks['text_print'] = {
    init: function() {
      this.appendValueInput('VALUE')
          .setCheck(null)
          .appendField('print');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(160);
      this.setTooltip('Print to console');
    }
  };

  // List Blocks
  Blockly.Blocks['lists_create_with'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldLabel('create list'));
      this.appendValueInput("ITEM0")
          .setCheck(null)
          .appendField("[");
      this.appendValueInput("ITEM1")
          .setCheck(null)
          .appendField(",");
      this.appendValueInput("ITEM2")
          .setCheck(null)
          .appendField(",");
      this.setOutput(true, 'Array');
      this.setColour(260);
      this.setTooltip("Create a Python list");
    }
  };

  Blockly.Blocks['lists_getIndex'] = {
    init: function() {
      this.appendValueInput("LIST")
          .setCheck('Array')
          .appendField(new Blockly.FieldLabel('get item from list'));
      this.appendValueInput("INDEX")
          .setCheck('Number')
          .appendField("at index");
      this.setOutput(true, null);
      this.setColour(260);
      this.setTooltip("Get item from list at index");
    }
  };

  Blockly.Blocks['lists_setIndex'] = {
    init: function() {
      this.appendValueInput("LIST")
          .setCheck('Array')
          .appendField(new Blockly.FieldLabel('set list'));
      this.appendValueInput("INDEX")
          .setCheck('Number')
          .appendField("at index");
      this.appendValueInput("VALUE")
          .setCheck(null)
          .appendField("to");
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(260);
      this.setTooltip("Set item in list at index");
    }
  };

  // Dictionary Blocks
  Blockly.Blocks['dict_create'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldLabel('create dictionary'));
      this.appendValueInput("KEY0")
          .setCheck('String')
          .appendField("{");
      this.appendValueInput("VALUE0")
          .setCheck(null)
          .appendField(":");
      this.appendValueInput("KEY1")
          .setCheck('String')
          .appendField(",");
      this.appendValueInput("VALUE1")
          .setCheck(null)
          .appendField(":");
      this.setOutput(true, 'Dictionary');
      this.setColour(290);
      this.setTooltip("Create a Python dictionary");
    }
  };

  Blockly.Blocks['dict_get'] = {
    init: function() {
      this.appendValueInput("DICT")
          .setCheck('Dictionary')
          .appendField(new Blockly.FieldLabel('get value from dict'));
      this.appendValueInput("KEY")
          .setCheck('String')
          .appendField("with key");
      this.setOutput(true, null);
      this.setColour(290);
      this.setTooltip("Get value from dictionary by key");
    }
  };

  Blockly.Blocks['dict_set'] = {
    init: function() {
      this.appendValueInput("DICT")
          .setCheck('Dictionary')
          .appendField(new Blockly.FieldLabel('set dict'));
      this.appendValueInput("KEY")
          .setCheck('String')
          .appendField("key");
      this.appendValueInput("VALUE")
          .setCheck(null)
          .appendField("to");
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(290);
      this.setTooltip("Set value in dictionary for key");
    }
  };

  // Tuple Blocks
  Blockly.Blocks['tuple_create'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldLabel('create tuple'));
      this.appendValueInput("ITEM0")
          .setCheck(null)
          .appendField("(");
      this.appendValueInput("ITEM1")
          .setCheck(null)
          .appendField(",");
      this.setOutput(true, 'Tuple');
      this.setColour(320);
      this.setTooltip("Create a Python tuple");
    }
  };

  Blockly.Blocks['tuple_get'] = {
    init: function() {
      this.appendValueInput("TUPLE")
          .setCheck('Tuple')
          .appendField(new Blockly.FieldLabel('get item from tuple'));
      this.appendValueInput("INDEX")
          .setCheck('Number')
          .appendField("at index");
      this.setOutput(true, null);
      this.setColour(320);
      this.setTooltip("Get item from tuple at index");
    }
  };

  // Input Block
  Blockly.Blocks['input_text'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldLabel('input'))
          .appendField(new Blockly.FieldTextInput("prompt"), "PROMPT");
      this.setOutput(true, 'String');
      this.setColour(230);
      this.setTooltip("Get user input as text");
    }
  };

  // Variable Blocks with Proper Variable Management
  Blockly.Blocks['variables_get'] = {
    init: function() {
      this.appendDummyInput()
          .appendField(new Blockly.FieldVariable('variable'), 'VAR');
      this.setOutput(true, null);
      this.setColour(330);
      this.setTooltip('Get a variable value');
    }
  };

  Blockly.Blocks['variables_set'] = {
    init: function() {
      this.appendDummyInput()
          .appendField('set')
          .appendField(new Blockly.FieldVariable('variable'), 'VAR');
      this.appendValueInput('VALUE')
          .setCheck(null)
          .appendField('to');
      this.setPreviousStatement(true, null);
      this.setNextStatement(true, null);
      this.setColour(330);
      this.setTooltip('Set a variable value');
    }
  };
}

defineCustomBlocks();
console.log("All blocks defined");

// Custom Python code generation
function generatePythonCode(workspace) {
  console.log("Generating Python code independently");
  console.log("Top blocks in workspace:", workspace.getTopBlocks(true).map(block => block.type));
  const topBlocks = workspace.getTopBlocks(true);
  let code = '';
  for (const block of topBlocks) {
    console.log(`Processing top block: ${block.type}`);
    const blockCode = generateBlockCode(block, 0, workspace);
    console.log(`Generated code for block ${block.type}: ${blockCode}`);
    code += blockCode + '\n';
  }
  const finalCode = code || '# No code generated\n';
  console.log("Final generated code:\n", finalCode);
  return finalCode;
}

function generateBlockCode(block, indentLevel, workspace) {
  const indent = '  '.repeat(indentLevel);
  let code = '';
  console.log(`Generating code for block: ${block.type} at indent level: ${indentLevel}`);

  switch (block.type) {
    // Control Blocks
    case 'controls_if': {
      const ifCondition = generateValueCode(block.getInputTargetBlock('IF0'), workspace) || 'False';
      console.log(`If condition: ${ifCondition}`);
      const ifBranch = generateStatementCode(block.getInput('DO0'), indentLevel + 1, workspace);
      code = `[other]${indent}if ${ifCondition}:\n${ifBranch}`;
      break;
    }
    case 'controls_if_else': {
      const ifElseCondition = generateValueCode(block.getInputTargetBlock('IF0'), workspace) || 'False';
      console.log(`If-else condition: ${ifElseCondition}`);
      const ifElseBranch = generateStatementCode(block.getInput('DO0'), indentLevel + 1, workspace);
      const elseBranch = generateStatementCode(block.getInput('ELSE'), indentLevel + 1, workspace);
      code = `[other]${indent}if ${ifElseCondition}:\n${ifElseBranch}[other]${indent}else:\n${elseBranch}`;
      break;
    }
    case 'controls_ifelseif': {
      const ifCondition1 = generateValueCode(block.getInputTargetBlock('IF0'), workspace) || 'False';
      const ifBranch1 = generateStatementCode(block.getInput('DO0'), indentLevel + 1, workspace);
      const elifCondition = generateValueCode(block.getInputTargetBlock('IF1'), workspace) || 'False';
      console.log(`If-elseif conditions: if(${ifCondition1}), elif(${elifCondition})`);
      const elifBranch = generateStatementCode(block.getInput('DO1'), indentLevel + 1, workspace);
      const elseBranchIfElseIf = generateStatementCode(block.getInput('ELSE'), indentLevel + 1, workspace);
      code = `[other]${indent}if ${ifCondition1}:\n${ifBranch1}[other]${indent}elif ${elifCondition}:\n${elifBranch}[other]${indent}else:\n${elseBranchIfElseIf}`;
      break;
    }
    case 'controls_for': {
      const varId = block.getFieldValue('VAR');
      const variable = workspace.getVariableById(varId)?.name || 'i';
      const from = generateValueCode(block.getInputTargetBlock('FROM'), workspace) || '0';
      const to = generateValueCode(block.getInputTargetBlock('TO'), workspace) || '0';
      console.log(`For loop: var=${variable}, from=${from}, to=${to}`);
      const forBranch = generateStatementCode(block.getInput('DO'), indentLevel + 1, workspace);
      code = `[loop]${indent}for ${variable} in range(${from}, ${to} + 1):\n${forBranch}`;
      break;
    }
    case 'controls_whileUntil': {
      const whileCondition = generateValueCode(block.getInputTargetBlock('BOOL'), workspace) || 'False';
      console.log(`While condition: ${whileCondition}`);
      const whileBranch = generateStatementCode(block.getInput('DO'), indentLevel + 1, workspace);
      code = `[loop]${indent}while ${whileCondition}:\n${whileBranch}`;
      break;
    }
    case 'import_statement': {
      const module = block.getFieldValue('MODULE') || '';
      console.log(`Import statement: module=${module}`);
      code = `[import]${indent}import ${module}`;
      break;
    }

    // Variable Blocks
    case 'variables_get': {
      const varId = block.getFieldValue('VAR');
      const variable = workspace.getVariableById(varId);
      const varNameGet = variable ? variable.name : 'var1';
      console.log(`Variables_get: varId=${varId}, raw varName=${varNameGet}`);
      // Sanitize variable name to ensure it's a valid Python identifier
      const sanitizedVarName = varNameGet.replace(/[^a-zA-Z0-9_]/g, '_').replace(/^\d/, '_$&') || 'var1';
      console.log(`Variables_get: sanitized varName=${sanitizedVarName}`);
      code = sanitizedVarName;
      break;
    }
    case 'variables_set': {
      const varId = block.getFieldValue('VAR');
      const variable = workspace.getVariableById(varId);
      const varNameSet = variable ? variable.name : 'var1';
      console.log(`Variables_set: varId=${varId}, raw varName=${varNameSet}`);
      // Sanitize variable name to ensure it's a valid Python identifier
      const sanitizedVarName = varNameSet.replace(/[^a-zA-Z0-9_]/g, '_').replace(/^\d/, '_$&') || 'var1';
      console.log(`Variables_set: sanitized varName=${sanitizedVarName}`);
      const valueSet = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || 'None';
      console.log(`Variables_set: value=${valueSet}`);
      code = `[other]${indent}${sanitizedVarName} = ${valueSet}`;
      break;
    }

    // Logic Blocks
    case 'logic_compare': {
      const aCompare = generateValueCode(block.getInputTargetBlock('A'), workspace) || '0';
      const bCompare = generateValueCode(block.getInputTargetBlock('B'), workspace) || '0';
      const opCompare = block.getFieldValue('OP') || 'EQ';
      console.log(`Logic_compare: A=${aCompare}, OP=${opCompare}, B=${bCompare}`);
      const opMap = { 'EQ': '==', 'NEQ': '!=', 'LT': '<', 'LTE': '<=', 'GT': '>', 'GTE': '>=' };
      code = `${aCompare} ${opMap[opCompare]} ${bCompare}`;
      break;
    }
    case 'logic_operation': {
      const aOp = generateValueCode(block.getInputTargetBlock('A'), workspace) || 'False';
      const bOp = generateValueCode(block.getInputTargetBlock('B'), workspace) || 'False';
      const opLogic = block.getFieldValue('OP') || 'AND';
      console.log(`Logic_operation: A=${aOp}, OP=${opLogic}, B=${bOp}`);
      code = `${aOp} ${opLogic.toLowerCase()} ${bOp}`;
      break;
    }
    case 'logic_boolean': {
      const boolValue = block.getFieldValue('BOOL') === 'TRUE' ? 'True' : 'False';
      console.log(`Logic_boolean: value=${boolValue}`);
      code = boolValue;
      break;
    }

    // Math Blocks
    case 'math_number': {
      const numValue = block.getFieldValue('NUM');
      console.log(`Math_number: value=${numValue}`);
      code = numValue !== undefined ? numValue.toString() : '0';
      break;
    }
    case 'math_arithmetic': {
      const aMath = generateValueCode(block.getInputTargetBlock('A'), workspace) || '0';
      const bMath = generateValueCode(block.getInputTargetBlock('B'), workspace) || '0';
      const opMath = block.getFieldValue('OP') || 'ADD';
      console.log(`Math_arithmetic: A=${aMath}, OP=${opMath}, B=${bMath}`);
      const mathOpMap = { 'ADD': '+', 'MINUS': '-', 'MULTIPLY': '*', 'DIVIDE': '/' };
      code = `${aMath} ${mathOpMap[opMath]} ${bMath}`;
      break;
    }
    case 'math_round': {
      const roundValue = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || '0';
      console.log(`Math_round: value=${roundValue}`);
      code = `round(${roundValue})`;
      break;
    }

    // Text Blocks
    case 'text': {
      const textValue = block.getFieldValue('TEXT') || '';
      console.log(`Text: value="${textValue}"`);
      code = `"${textValue}"`;
      break;
    }
    case 'text_print': {
      const printValue = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || '""';
      console.log(`Text_print: value=${printValue}`);
      code = `[other]${indent}print(${printValue})`;
      break;
    }

    // List Blocks
    case 'lists_create_with': {
      const listItems = [];
      for (let i = 0; i < 3; i++) {
        const item = generateValueCode(block.getInputTargetBlock('ITEM' + i), workspace);
        listItems.push(item || 'None');
        console.log(`Lists_create_with: item${i}=${item || 'None'}`);
      }
      code = `[${listItems.join(', ')}]`;
      break;
    }
    case 'lists_getIndex': {
      const listGet = generateValueCode(block.getInputTargetBlock('LIST'), workspace) || '[]';
      const indexGet = generateValueCode(block.getInputTargetBlock('INDEX'), workspace) || '0';
      console.log(`Lists_getIndex: list=${listGet}, index=${indexGet}`);
      code = `${listGet}[${indexGet}]`;
      break;
    }
    case 'lists_setIndex': {
      const listSet = generateValueCode(block.getInputTargetBlock('LIST'), workspace) || '[]';
      const indexSet = generateValueCode(block.getInputTargetBlock('INDEX'), workspace) || '0';
      const valueSet = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || 'None';
      console.log(`Lists_setIndex: list=${listSet}, index=${indexSet}, value=${valueSet}`);
      code = `[other]${indent}${listSet}[${indexSet}] = ${valueSet}`;
      break;
    }

    // Dictionary Blocks
    case 'dict_create': {
      const dictEntries = [];
      for (let i = 0; i < 2; i++) {
        const key = generateValueCode(block.getInputTargetBlock('KEY' + i), workspace) || '""';
        const value = generateValueCode(block.getInputTargetBlock('VALUE' + i), workspace) || 'None';
        dictEntries.push(`${key}: ${value}`);
        console.log(`Dict_create: key${i}=${key}, value${i}=${value}`);
      }
      code = `{${dictEntries.join(', ')}}`;
      break;
    }
    case 'dict_get': {
      const dictGet = generateValueCode(block.getInputTargetBlock('DICT'), workspace) || '{}';
      const keyGet = generateValueCode(block.getInputTargetBlock('KEY'), workspace) || '""';
      console.log(`Dict_get: dict=${dictGet}, key=${keyGet}`);
      code = `${dictGet}[${keyGet}]`;
      break;
    }
    case 'dict_set': {
      const dictSet = generateValueCode(block.getInputTargetBlock('DICT'), workspace) || '{}';
      const keySet = generateValueCode(block.getInputTargetBlock('KEY'), workspace) || '""';
      const valueSet = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || 'None';
      console.log(`Dict_set: dict=${dictSet}, key=${keySet}, value=${valueSet}`);
      code = `[other]${indent}${dictSet}[${keySet}] = ${valueSet}`;
      break;
    }

    // Tuple Blocks
    case 'tuple_create': {
      const tupleItems = [];
      for (let i = 0; i < 2; i++) {
        const item = generateValueCode(block.getInputTargetBlock('ITEM' + i), workspace);
        tupleItems.push(item || 'None');
        console.log(`Tuple_create: item${i}=${item || 'None'}`);
      }
      code = `(${tupleItems.join(', ')})`;
      break;
    }
    case 'tuple_get': {
      const tupleGet = generateValueCode(block.getInputTargetBlock('TUPLE'), workspace) || '()';
      const indexTuple = generateValueCode(block.getInputTargetBlock('INDEX'), workspace) || '0';
      console.log(`Tuple_get: tuple=${tupleGet}, index=${indexTuple}`);
      code = `${tupleGet}[${indexTuple}]`;
      break;
    }

    // Input Block
    case 'input_text': {
      const prompt = block.getFieldValue('PROMPT') || '';
      console.log(`Input_text: prompt="${prompt}"`);
      code = `input("${prompt}")`;
      break;
    }

    default: {
      console.log(`Unsupported block type: ${block.type}`);
      code = `[other]${indent}# Unsupported block type: ${block.type}`;
    }
  }

  const nextBlock = block.getNextBlock();
  if (nextBlock) {
    console.log(`Processing next block: ${nextBlock.type}`);
    const nextCode = generateBlockCode(nextBlock, indentLevel, workspace);
    code += '\n' + nextCode;
  }

  return code;
}

function generateValueCode(block, workspace) {
  if (!block) {
    console.log("GenerateValueCode: Block is null");
    return null;
  }

  console.log(`Generating value code for block: ${block.type}`);

  switch (block.type) {
    // Variable Blocks
    case 'variables_get': {
      const varId = block.getFieldValue('VAR');
      const variable = workspace.getVariableById(varId);
      const varNameGet = variable ? variable.name : 'var1';
      console.log(`Variables_get (value): varId=${varId}, raw varName=${varNameGet}`);
      // Sanitize variable name to ensure it's a valid Python identifier
      const sanitizedVarName = varNameGet.replace(/[^a-zA-Z0-9_]/g, '_').replace(/^\d/, '_$&') || 'var1';
      console.log(`Variables_get (value): sanitized varName=${sanitizedVarName}`);
      return sanitizedVarName;
    }
    case 'variables_set': {
      const varId = block.getFieldValue('VAR');
      const variable = workspace.getVariableById(varId);
      const varNameSet = variable ? variable.name : 'var1';
      console.log(`Variables_set (value): varId=${varId}, raw varName=${varNameSet}`);
      // Sanitize variable name to ensure it's a valid Python identifier
      const sanitizedVarName = varNameSet.replace(/[^a-zA-Z0-9_]/g, '_').replace(/^\d/, '_$&') || 'var1';
      console.log(`Variables_set (value): sanitized varName=${sanitizedVarName}`);
      const valueSet = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || 'None';
      console.log(`Variables_set (value): value=${valueSet}`);
      return `${sanitizedVarName} = ${valueSet}`; // This should not be called in value context
    }

    // Logic Blocks
    case 'logic_compare': {
      const aCompare = generateValueCode(block.getInputTargetBlock('A'), workspace) || '0';
      const bCompare = generateValueCode(block.getInputTargetBlock('B'), workspace) || '0';
      const opCompare = block.getFieldValue('OP') || 'EQ';
      console.log(`Logic_compare (value): A=${aCompare}, OP=${opCompare}, B=${bCompare}`);
      const opMap = { 'EQ': '==', 'NEQ': '!=', 'LT': '<', 'LTE': '<=', 'GT': '>', 'GTE': '>=' };
      return `${aCompare} ${opMap[opCompare]} ${bCompare}`;
    }
    case 'logic_operation': {
      const aOp = generateValueCode(block.getInputTargetBlock('A'), workspace) || 'False';
      const bOp = generateValueCode(block.getInputTargetBlock('B'), workspace) || 'False';
      const opLogic = block.getFieldValue('OP') || 'AND';
      console.log(`Logic_operation (value): A=${aOp}, OP=${opLogic}, B=${bOp}`);
      return `${aOp} ${opLogic.toLowerCase()} ${bOp}`;
    }
    case 'logic_boolean': {
      const boolValue = block.getFieldValue('BOOL') === 'TRUE' ? 'True' : 'False';
      console.log(`Logic_boolean (value): value=${boolValue}`);
      return boolValue;
    }

    // Math Blocks
    case 'math_number': {
      const numValue = block.getFieldValue('NUM');
      console.log(`Math_number (value): value=${numValue}`);
      return numValue !== undefined ? numValue.toString() : '0';
    }
    case 'math_arithmetic': {
      const aMath = generateValueCode(block.getInputTargetBlock('A'), workspace) || '0';
      const bMath = generateValueCode(block.getInputTargetBlock('B'), workspace) || '0';
      const opMath = block.getFieldValue('OP') || 'ADD';
      console.log(`Math_arithmetic (value): A=${aMath}, OP=${opMath}, B=${bMath}`);
      const mathOpMap = { 'ADD': '+', 'MINUS': '-', 'MULTIPLY': '*', 'DIVIDE': '/' };
      return `${aMath} ${mathOpMap[opMath]} ${bMath}`;
    }
    case 'math_round': {
      const roundValue = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || '0';
      console.log(`Math_round (value): value=${roundValue}`);
      return `round(${roundValue})`;
    }

    // Text Blocks
    case 'text': {
      const textValue = block.getFieldValue('TEXT') || '';
      console.log(`Text (value): value="${textValue}"`);
      return `"${textValue}"`;
    }
    case 'text_print': {
      const printValue = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || '""';
      console.log(`Text_print (value): value=${printValue}`);
      return `print(${printValue})`; // This should not be called in value context
    }

    // List Blocks
    case 'lists_create_with': {
      const listItems = [];
      for (let i = 0; i < 3; i++) {
        const item = generateValueCode(block.getInputTargetBlock('ITEM' + i), workspace);
        listItems.push(item || 'None');
        console.log(`Lists_create_with (value): item${i}=${item || 'None'}`);
      }
      return `[${listItems.join(', ')}]`;
    }
    case 'lists_getIndex': {
      const listGet = generateValueCode(block.getInputTargetBlock('LIST'), workspace) || '[]';
      const indexGet = generateValueCode(block.getInputTargetBlock('INDEX'), workspace) || '0';
      console.log(`Lists_getIndex (value): list=${listGet}, index=${indexGet}`);
      return `${listGet}[${indexGet}]`;
    }
    case 'lists_setIndex': {
      const listSet = generateValueCode(block.getInputTargetBlock('LIST'), workspace) || '[]';
      const indexSet = generateValueCode(block.getInputTargetBlock('INDEX'), workspace) || '0';
      const valueSet = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || 'None';
      console.log(`Lists_setIndex (value): list=${listSet}, index=${indexSet}, value=${valueSet}`);
      return `${listSet}[${indexSet}] = ${valueSet}`; // This should not be called in value context
    }

    // Dictionary Blocks
    case 'dict_create': {
      const dictEntries = [];
      for (let i = 0; i < 2; i++) {
        const key = generateValueCode(block.getInputTargetBlock('KEY' + i), workspace) || '""';
        const value = generateValueCode(block.getInputTargetBlock('VALUE' + i), workspace) || 'None';
        dictEntries.push(`${key}: ${value}`);
        console.log(`Dict_create (value): key${i}=${key}, value${i}=${value}`);
      }
      return `{${dictEntries.join(', ')}}`;
    }
    case 'dict_get': {
      const dictGet = generateValueCode(block.getInputTargetBlock('DICT'), workspace) || '{}';
      const keyGet = generateValueCode(block.getInputTargetBlock('KEY'), workspace) || '""';
      console.log(`Dict_get (value): dict=${dictGet}, key=${keyGet}`);
      return `${dictGet}[${keyGet}]`;
    }
    case 'dict_set': {
      const dictSet = generateValueCode(block.getInputTargetBlock('DICT'), workspace) || '{}';
      const keySet = generateValueCode(block.getInputTargetBlock('KEY'), workspace) || '""';
      const valueSet = generateValueCode(block.getInputTargetBlock('VALUE'), workspace) || 'None';
      console.log(`Dict_set (value): dict=${dictSet}, key=${keySet}, value=${valueSet}`);
      return `${dictSet}[${keySet}] = ${valueSet}`; // This should not be called in value context
    }

    // Tuple Blocks
    case 'tuple_create': {
      const tupleItems = [];
      for (let i = 0; i < 2; i++) {
        const item = generateValueCode(block.getInputTargetBlock('ITEM' + i), workspace);
        tupleItems.push(item || 'None');
        console.log(`Tuple_create (value): item${i}=${item || 'None'}`);
      }
      return `(${tupleItems.join(', ')})`;
    }
    case 'tuple_get': {
      const tupleGet = generateValueCode(block.getInputTargetBlock('TUPLE'), workspace) || '()';
      const indexTuple = generateValueCode(block.getInputTargetBlock('INDEX'), workspace) || '0';
      console.log(`Tuple_get (value): tuple=${tupleGet}, index=${indexTuple}`);
      return `${tupleGet}[${indexTuple}]`;
    }

    // Input Block
    case 'input_text': {
      const prompt = block.getFieldValue('PROMPT') || '';
      console.log(`Input_text (value): prompt="${prompt}"`);
      return `input("${prompt}")`;
    }

    default: {
      console.log(`Unsupported block type in value context: ${block.type}`);
      return `# Unsupported block type: ${block.type}`;
    }
  }
}

function generateStatementCode(input, indentLevel, workspace) {
  const block = input.connection.targetBlock();
  if (!block) {
    console.log(`GenerateStatementCode: No block connected at indent level ${indentLevel}`);
    return `[other]${'  '.repeat(indentLevel)}pass\n`;
  }
  console.log(`GenerateStatementCode: Processing block ${block.type} at indent level ${indentLevel}`);
  return generateBlockCode(block, indentLevel, workspace);
}

function waitForBlockly(callback, timeout = 10000, startTime = Date.now()) {
  if (typeof Blockly !== 'undefined') {
    console.log("Blockly loaded");
    isBlocklyLoaded = true;
    callback();
  } else if (Date.now() - startTime > timeout) {
    console.log("Error: Timed out waiting for Blockly");
    const loadingContainer = document.querySelector('.loading-container');
    if (loadingContainer) {
      loadingContainer.style.display = 'none';
    }
    if (window.PythonChannel) {
      window.PythonChannel.postMessage(JSON.stringify({
        type: "error",
        message: "Timed out waiting for Blockly"
      }));
    }
  } else {
    console.log("Waiting for Blockly...");
    setTimeout(() => waitForBlockly(callback, timeout, startTime), 100);
  }
}

// Function to validate and sanitize variable names
function sanitizeVariableName(name, index) {
  if (!name || typeof name !== 'string') {
    console.log(`Invalid variable name: ${name}, using default var${index + 1}`);
    return `var${index + 1}`;
  }
  // Check if the name contains only valid characters (letters, numbers, underscore)
  const isValid = /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(name);
  if (!isValid) {
    console.log(`Variable name "${name}" contains invalid characters, sanitizing`);
    const sanitized = name.replace(/[^a-zA-Z0-9_]/g, '_').replace(/^\d/, '_$&') || `var${index + 1}`;
    console.log(`Sanitized variable name: ${name} -> ${sanitized}`);
    return sanitized;
  }
  return name;
}

function initializeWorkspace() {
  console.log("Blockly ready, initializing workspace");

  // Check if the workspace is already initialized
  if (cachedWorkspace) {
    console.log("Using cached workspace");
    // Restore the workspace state if available
    if (cachedWorkspaceXml) {
      console.log("Restoring workspace state from cached XML");
      Blockly.Xml.clearWorkspaceAndLoadFromXml(Blockly.Xml.textToDom(cachedWorkspaceXml), cachedWorkspace);
    }
    // Resize the workspace and show it
    resizeWorkspace();
    const loadingContainer = document.querySelector('.loading-container');
    if (loadingContainer) {
      loadingContainer.style.display = 'none';
      console.log("Loading container hidden after using cached workspace");
    }
    // Generate and send the initial code
    const initialCode = generatePythonCode(cachedWorkspace);
    if (window.PythonChannel) {
      console.log("Sending initial code to PythonChannel from cached workspace:", initialCode);
      window.PythonChannel.postMessage(JSON.stringify({
        type: "python",
        code: initialCode
      }));
    }
    return;
  }

  const workspace = Blockly.getMainWorkspace();
  if (!workspace) {
    console.log("Error: Workspace not found");
    const loadingContainer = document.querySelector('.loading-container');
    if (loadingContainer) {
      loadingContainer.style.display = 'none';
    }
    if (window.PythonChannel) {
      window.PythonChannel.postMessage(JSON.stringify({
        type: "error",
        message: "Workspace not initialized"
      }));
    }
    return;
  }

  cachedWorkspace = workspace;

  // Override the createVariable method to validate names
  const originalCreateVariable = workspace.createVariable;
  workspace.createVariable = function(name, opt_type, opt_id) {
    console.log(`Creating variable with name: "${name}"`);
    const sanitizedName = sanitizeVariableName(name, workspace.getAllVariables().length);
    if (name !== sanitizedName) {
      console.log(`Variable name sanitized during creation: ${name} -> ${sanitizedName}`);
    }
    return originalCreateVariable.call(this, sanitizedName, opt_type, opt_id);
  };

  // Sanitize all existing variable names in the workspace
  const allVariables = workspace.getAllVariables();
  console.log("Workspace variables before sanitization:", allVariables.map(v => ({ name: v.name, id: v.getId() })));
  allVariables.forEach((variable, index) => {
    const originalName = variable.name;
    const sanitizedName = sanitizeVariableName(originalName, index);
    if (originalName !== sanitizedName) {
      console.log(`Sanitizing existing variable: ${originalName} -> ${sanitizedName}`);
      // Create a new variable with the sanitized name
      const newVariable = workspace.createVariable(sanitizedName);
      // Update all blocks to reference the new variable
      workspace.getBlocksByType('variables_get').forEach(block => {
        if (block.getFieldValue('VAR') === originalName) {
          block.setFieldValue(newVariable.getId(), 'VAR');
        }
      });
      workspace.getBlocksByType('variables_set').forEach(block => {
        if (block.getFieldValue('VAR') === originalName) {
          block.setFieldValue(newVariable.getId(), 'VAR');
        }
      });
      // Delete the old variable
      workspace.deleteVariableById(variable.getId());
    }
  });
  console.log("Workspace variables after sanitization:", workspace.getAllVariables().map(v => ({ name: v.name, id: v.getId() })));

  // Log variable creation and rename events
  workspace.addChangeListener((event) => {
    if (event.type === Blockly.Events.VAR_CREATE) {
      console.log(`Variable created: name="${event.varName}", id=${event.varId}`);
    } else if (event.type === Blockly.Events.VAR_RENAME) {
      console.log(`Variable renamed: oldName=${event.oldName}, newName=${event.newName}, id=${event.varId}`);
    }
  });

  // Add icons to toolbox categories
  document.querySelectorAll('.blocklyTreeRow').forEach(row => {
    const categoryName = row.textContent.trim();
    const iconMap = {
      'Variables': 'fas fa-cube',
      'Control': 'fas fa-sync',
      'Logic': 'fas fa-arrows-alt-h',
      'Math': 'fas fa-calculator',
      'Text': 'fas fa-font',
      'Lists': 'fas fa-list',
      'Dictionaries': 'fas fa-book',
      'Tuples': 'fas fa-object-group',
      'Input': 'fas fa-keyboard'
    };
    if (iconMap[categoryName]) {
      row.innerHTML = `<i class="${iconMap[categoryName]} fa-icon"></i>${categoryName}`;
    }
  });

  // Add icons to blocks dynamically
  const addIconsToBlocks = () => {
    const iconMap = {
      'controls_if': 'fas fa-sync',
      'controls_if_else': 'fas fa-sync',
      'controls_ifelseif': 'fas fa-sync',
      'controls_for': 'fas fa-sync',
      'controls_whileUntil': 'fas fa-sync',
      'import_statement': 'fas fa-sync',
      'input_text': 'fas fa-keyboard',
      'lists_create_with': 'fas fa-list',
      'lists_getIndex': 'fas fa-list',
      'lists_setIndex': 'fas fa-list',
      'dict_create': 'fas fa-book',
      'dict_get': 'fas fa-book',
      'dict_set': 'fas fa-book',
      'tuple_create': 'fas fa-object-group',
      'tuple_get': 'fas fa-object-group'
    };

    workspace.getAllBlocks().forEach(block => {
      const blockType = block.type;
      if (iconMap[blockType]) {
        const labelField = block.inputList[0]?.fieldRow?.find(field => field instanceof Blockly.FieldLabel);
        if (labelField) {
          const labelElement = labelField.getSvgRoot();
          if (labelElement && !labelElement.querySelector('.fa-icon')) {
            const icon = document.createElementNS('http://www.w3.org/2000/svg', 'tspan');
            icon.setAttribute('class', `${iconMap[blockType]} fa-icon`);
            icon.setAttribute('dx', '-15');
            labelElement.insertBefore(icon, labelElement.firstChild);
          }
        }
      }
    });
  };

  addIconsToBlocks();
  workspace.addChangeListener((event) => {
    if (event.type === Blockly.Events.BLOCK_CREATE || event.type === Blockly.Events.BLOCK_MOVE) {
      addIconsToBlocks();
    }
  });

  workspace.options.moveOptions.drag = true;
  workspace.options.zoomOptions.controls = false;
  workspace.rendered = true;

  const resizeWorkspace = () => {
    const blocklyDiv = document.getElementById('blocklyEditor');
    if (blocklyDiv && workspace) {
      blocklyDiv.style.height = '100%';
      blocklyDiv.style.width = '100%';
      const svg = document.querySelector('.blocklySvg');
      if (svg) {
        svg.style.height = '100%';
        svg.style.width = '100%';
      }
      Blockly.svgResize(workspace);
      console.log("Workspace resized");
    }
  };

  // Hide the loading container once the workspace is fully initialized
  const loadingContainer = document.querySelector('.loading-container');
  if (loadingContainer) {
    loadingContainer.style.display = 'none';
    console.log("Loading container hidden after workspace initialization");
  }

  resizeWorkspace();
  window.addEventListener('resize', resizeWorkspace);
  workspace.addChangeListener((event) => {
    if (event.type === Blockly.Events.TOOLBOX_ITEM_SELECT || event.type === Blockly.Events.VIEWPORT_CHANGE) {
      setTimeout(resizeWorkspace, 100);
    }
  });

  workspace.addChangeListener(() => {
    console.log("Workspace changed, generating new Python code");
    const code = generatePythonCode(workspace);
    // Cache the workspace state as XML
    cachedWorkspaceXml = Blockly.Xml.domToText(Blockly.Xml.workspaceToDom(workspace));
    console.log("Cached workspace XML:", cachedWorkspaceXml);
    if (window.PythonChannel) {
      console.log("Sending code to PythonChannel:", code);
      window.PythonChannel.postMessage(JSON.stringify({
        type: "python",
        code: code
      }));
      // Optionally send the workspace XML to Flutter for persistent storage
      window.PythonChannel.postMessage(JSON.stringify({
        type: "workspace",
        xml: cachedWorkspaceXml
      }));
    }
  });

  const initialCode = generatePythonCode(workspace);
  if (window.PythonChannel) {
    console.log("Sending initial code to PythonChannel:", initialCode);
    window.PythonChannel.postMessage(JSON.stringify({
      type: "python",
      code: initialCode
    }));
  }
}

// Check if Blockly is already loaded and initialize immediately
if (isBlocklyLoaded) {
  console.log("Blockly already loaded, initializing workspace immediately");
  initializeWorkspace();
} else {
  waitForBlockly(initializeWorkspace);
}

// Expose a function to Flutter to restore the workspace
window.restoreWorkspace = function(xmlText) {
  if (cachedWorkspace && xmlText) {
    console.log("Restoring workspace from Flutter-provided XML:", xmlText);
    cachedWorkspaceXml = xmlText;
    Blockly.Xml.clearWorkspaceAndLoadFromXml(Blockly.Xml.textToDom(xmlText), cachedWorkspace);
    const code = generatePythonCode(cachedWorkspace);
    if (window.PythonChannel) {
      console.log("Sending restored code to PythonChannel:", code);
      window.PythonChannel.postMessage(JSON.stringify({
        type: "python",
        code: code
      }));
    }
  }
};