# frozen_string_literal: true

RSpec.describe MiniCSS::Sel do
  it "parses ul > li:nth-of-type(2n+1):not(:last-child) a" do
    input = "ul > li:nth-of-type(2n+1):not(:last-child) a"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :complex,
      combinator: " ",
      left: {
        type: :complex,
        combinator: ">",
        left: {
          name: "ul",
          type: :type,
          content: "ul",
          pos: [0, 2]
        },
        right: {
          type: :compound,
          list: [
            {
              name: "li",
              type: :type,
              content: "li",
              pos: [5, 7]
            },
            {
              name: "nth-of-type",
              argument: "2n+1",
              type: :pseudo_class,
              content: ":nth-of-type(2n+1)",
              pos: [7, 25]
            },
            {
              name: "not",
              argument: ":last-child",
              type: :pseudo_class,
              content: ":not(:last-child)",
              pos: [25, 42],
              subtree: {
                name: "last-child",
                type: :pseudo_class,
                content: ":last-child",
                pos: [0, 11]
              }
            }
          ]
        }
      },
      right: {
        name: "a",
        type: :type,
        content: "a",
        pos: [43, 44]
      }
    })
  end

  it "parses .box:not(:first-child):not(:last-child) p:first-child" do
    input = ".box:not(:first-child):not(:last-child) p:first-child"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :complex,
      combinator: " ",
      left: {
        type: :compound,
        list: [
          {
            name: "box",
            type: :class,
            content: ".box",
            pos: [0, 4]
          },
          {
            name: "not",
            argument: ":first-child",
            type: :pseudo_class,
            content: ":not(:first-child)",
            pos: [4, 22],
            subtree: {
              name: "first-child",
              type: :pseudo_class,
              content: ":first-child",
              pos: [0, 12]
            }
          },
          {
            name: "not",
            argument: ":last-child",
            type: :pseudo_class,
            content: ":not(:last-child)",
            pos: [22, 39],
            subtree: {
              name: "last-child",
              type: :pseudo_class,
              content: ":last-child",
              pos: [0, 11]
            }
          }
        ]
      },
      right: {
        type: :compound,
        list: [
          {
            name: "p",
            type: :type,
            content: "p",
            pos: [40, 41]
          },
          {
            name: "first-child",
            type: :pseudo_class,
            content: ":first-child",
            pos: [41, 53]
          }
        ]
      }
    })
  end

  it "parses form:target input[type=\"submit\"]" do
    input = "form:target input[type=\"submit\"]"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :complex,
      combinator: " ",
      left: {
        type: :compound,
        list: [
          {
            name: "form",
            type: :type,
            content: "form",
            pos: [0, 4]
          },
          {
            name: "target",
            type: :pseudo_class,
            content: ":target",
            pos: [4, 11]
          }
        ]
      },
      right: {
        type: :compound,
        list: [
          {
            name: "input",
            type: :type,
            content: "input",
            pos: [12, 17]
          },
          {
            name: "type",
            operator: "=",
            value: "\"submit\"",
            type: :attribute,
            content: "[type=\"submit\"]",
            pos: [17, 32]
          }
        ]
      }
    })
  end

  it "parses div:nth-child(odd):not(.highlight) p:first-letter" do
    input = "div:nth-child(odd):not(.highlight) p:first-letter"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :complex,
      combinator: " ",
      left: {
        type: :compound,
        list: [
          {
            name: "div",
            type: :type,
            content: "div",
            pos: [0, 3]
          },
          {
            name: "nth-child",
            argument: "odd",
            type: :pseudo_class,
            content: ":nth-child(odd)",
            pos: [3, 18]
          },
          {
            name: "not",
            argument: ".highlight",
            type: :pseudo_class,
            content: ":not(.highlight)",
            pos: [18, 34],
            subtree: {
              name: "highlight",
              type: :class,
              content: ".highlight",
              pos: [0, 10]
            }
          }
        ]
      },
      right: {
        type: :compound,
        list: [
          {
            name: "p",
            type: :type,
            content: "p",
            pos: [35, 36]
          },
          {
            name: "first-letter",
            type: :pseudo_class,
            content: ":first-letter",
            pos: [36, 49]
          }
        ]
      }
    })
  end

  it "parses nav ul li:first-child a, nav ul li:last-child a" do
    input = "nav ul li:first-child a, nav ul li:last-child a"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :list,
      list: [
        {
          type: :complex,
          combinator: " ",
          left: {
            type: :complex,
            combinator: " ",
            left: {
              type: :complex,
              combinator: " ",
              left: {
                name: "nav",
                type: :type,
                content: "nav",
                pos: [0, 3]
              },
              right: {
                name: "ul",
                type: :type,
                content: "ul",
                pos: [4, 6]
              }
            },
            right: {
              type: :compound,
              list: [
                {
                  name: "li",
                  type: :type,
                  content: "li",
                  pos: [7, 9]
                },
                {
                  name: "first-child",
                  type: :pseudo_class,
                  content: ":first-child",
                  pos: [9, 21]
                }
              ]
            }
          },
          right: {
            name: "a",
            type: :type,
            content: "a",
            pos: [22, 23]
          }
        },
        {
          type: :complex,
          combinator: " ",
          left: {
            type: :complex,
            combinator: " ",
            left: {
              type: :complex,
              combinator: " ",
              left: {
                name: "nav",
                type: :type,
                content: "nav",
                pos: [25, 28]
              },
              right: {
                name: "ul",
                type: :type,
                content: "ul",
                pos: [29, 31]
              }
            },
            right: {
              type: :compound,
              list: [
                {
                  name: "li",
                  type: :type,
                  content: "li",
                  pos: [32, 34]
                },
                {
                  name: "last-child",
                  type: :pseudo_class,
                  content: ":last-child",
                  pos: [34, 45]
                }
              ]
            }
          },
          right: {
            name: "a",
            type: :type,
            content: "a",
            pos: [46, 47]
          }
        }
      ]
    })
  end

  it "parses table td:first-of-type + td:last-of-type" do
    input = "table td:first-of-type + td:last-of-type"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :complex,
      combinator: "+",
      left: {
        type: :complex,
        combinator: " ",
        left: {
          name: "table",
          type: :type,
          content: "table",
          pos: [0, 5]
        },
        right: {
          type: :compound,
          list: [
            {
              name: "td",
              type: :type,
              content: "td",
              pos: [6, 8]
            },
            {
              name: "first-of-type",
              type: :pseudo_class,
              content: ":first-of-type",
              pos: [8, 22]
            }
          ]
        }
      },
      right: {
        type: :compound,
        list: [
          {
            name: "td",
            type: :type,
            content: "td",
            pos: [25, 27]
          },
          {
            name: "last-of-type",
            type: :pseudo_class,
            content: ":last-of-type",
            pos: [27, 40]
          }
        ]
      }
    })
  end

  it "parses :where()" do
    input = ":where()"
    r = described_class.parse(input)
    expect(r).to eq({
      name: "where",
      argument: "",
      type: :pseudo_class,
      content: ":where()",
      pos: [0, 8]
    })
  end

  it "parses .container:has(~ .image)" do
    input = ".container:has(~ .image)"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :compound,
      list: [
        {
          name: "container",
          type: :class,
          content: ".container",
          pos: [0, 10]
        },
        {
          name: "has",
          argument: "~ .image",
          type: :pseudo_class,
          content: ":has(~ .image)",
          pos: [10, 24],
          subtree: {
            type: :relative,
            combinator: "~",
            right: {
              name: "image",
              type: :class,
              content: ".image",
              pos: [2, 8]
            }
          }
        }
      ]
    })
  end

  it "parses [data-role=\"primary\"] .label" do
    input = "[data-role=\"primary\"] .label"
    r = described_class.parse(input)
    expect(r).to eq({
      type: :complex,
      combinator: " ",
      left: {
        name: "data-role",
        operator: "=",
        value: "\"primary\"",
        type: :attribute,
        content: "[data-role=\"primary\"]",
        pos: [0, 21]
      },
      right: {
        name: "label",
        type: :class,
        content: ".label",
        pos: [22, 28]
      }
    })
  end
end
