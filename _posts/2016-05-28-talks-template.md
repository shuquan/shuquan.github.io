---
layout: slide
title: "Shuquan's Talk Template"
date: 2016-05-28
categories: presentation
theme: league
transition: slide
---
<section data-markdown>
##Title and Content Example 1
###Title and Content Example 2
</section>
<section data-markdown>
An introductory line or paragraph
</section>
<section data-markdown>
###`bold`

- Bullet `one`
- Bullet `two`

###`bold`

- Bullet `one`
- Bullet `two`
- Bullet `three`

Text Example
</section>
<section>
    <section data-markdown>
        <pre><code>
```ruby
module Motion
  def default_movement
    "walking"
    end
  end
end

```
        </code></pre>
    </section>
    <section data-markdown>
        <pre><code>
```ruby
RSpec.describe "Ruby composition methods" do
  describe "extend" do
    context "when a class extends a module" do
      it "adds the module methods to the class's class methods" do
        expect(Person.default_movement).to eq("walking")
      end

      it "does not add the module methods to the class's instance methods" do
        person = Person.new

        expect { person.default_movement }.to raise_error(NoMethodError)
      end
    end

    context "when an object extends a module" do
      it "gains the modules methods" do
        cat = Cat.new

        cat.extend(Speech)
        expect(cat.greet).to eq("Hello World")
      end
    end
  end
end
```
        </code></pre>
    </section>
</section>
<section>
    <section data-markdown>
    The Two Content Example(1)
    </section>
    <section data-markdown>
    The Two Content Example(2)
    </section>
</section>
<section data-markdown>
###Questions
####and hopefully, answers</h4>
Check out my blog:
shuquan.github.io
</section>
