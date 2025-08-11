function generateChangeNumber() {
  const randomNum = Math.floor(100000 + Math.random() * 900000);
  return `TFS${randomNum}`;
}

return [{ json: { change_number: generateChangeNumber() } }];